import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/smart_routines/domain/smart_routines_domain.dart';

void main() {
  const factory = RoutineAdherenceEventFactory();
  const projector = RoutineAdherenceProjector();

  group('append-only events', () {
    test('factory creates typed immutable facts with relational IDs', () {
      final occurrence = _occurrence();
      final taken = factory.taken(
        occurrence: occurrence,
        eventId: _eventId(1),
        occurredAtUtc: _target,
        recordedAtUtc: _target.add(const Duration(minutes: 1)),
        actor: AdherenceEventActor.user,
        note: ' registered ',
      );
      final skipped = factory.skipped(
        occurrence: occurrence,
        eventId: _eventId(2),
        occurredAtUtc: _target,
        recordedAtUtc: _target,
        actor: AdherenceEventActor.caregiver,
      );
      final rescheduled = factory.rescheduled(
        occurrence: occurrence,
        eventId: _eventId(3),
        occurredAtUtc: _target,
        recordedAtUtc: _target,
        actor: AdherenceEventActor.user,
        newWindow: _window(_target.add(const Duration(hours: 2))),
      );
      final correction = factory.correction(
        occurrence: occurrence,
        eventId: _eventId(4),
        referencedEvent: skipped,
        action: AdherenceCorrectionAction.replace,
        replacementType: AdherenceEventType.taken,
        replacementOccurredAtUtc: _target,
        occurredAtUtc: _target.add(const Duration(minutes: 2)),
        recordedAtUtc: _target.add(const Duration(minutes: 2)),
        actor: AdherenceEventActor.user,
      );

      expect(taken.routineId, occurrence.routineId);
      expect(taken.note, 'registered');
      expect(skipped.type, AdherenceEventType.skipped);
      expect(rescheduled.rescheduledWindow, isNotNull);
      expect(correction.referencedEventId, skipped.eventId);
      expect(correction.replacementType, AdherenceEventType.taken);
    });

    test('non-UTC input and foreign correction are rejected', () {
      final occurrence = _occurrence();
      expect(
        () => factory.taken(
          occurrence: occurrence,
          eventId: _eventId(1),
          occurredAtUtc: DateTime(2026, 7, 20),
          recordedAtUtc: _target,
          actor: AdherenceEventActor.user,
        ),
        throwsA(isA<SmartRoutineValidationException>()),
      );
      final foreign = factory.taken(
        occurrence: _occurrence(id: _occurrenceId2),
        eventId: _eventId(2),
        occurredAtUtc: _target,
        recordedAtUtc: _target,
        actor: AdherenceEventActor.user,
      );
      expect(
        () => factory.correction(
          occurrence: occurrence,
          eventId: _eventId(3),
          referencedEvent: foreign,
          action: AdherenceCorrectionAction.invalidate,
          occurredAtUtc: _target,
          recordedAtUtc: _target,
          actor: AdherenceEventActor.user,
        ),
        throwsA(isA<SmartRoutineValidationException>()),
      );
    });
  });

  group('deterministic projection', () {
    test('derives pending and missed without creating events', () {
      final occurrence = _occurrence();
      final before = projector.project(
        occurrence: occurrence,
        events: const [],
        evaluatedAtUtc: _target,
      );
      final atEnd = projector.project(
        occurrence: occurrence,
        events: const [],
        evaluatedAtUtc: occurrence.currentWindow.windowEndsAt,
      );
      expect(before.state, OccurrenceAdherenceState.pending);
      expect(atEnd.state, OccurrenceAdherenceState.missed);
      expect(atEnd.effectiveTimeline, isEmpty);
    });

    test('window boundaries and explicit early policy are classified', () {
      final occurrence = _occurrence();
      RoutineAdherenceProjection projectionAt(DateTime instant) =>
          projector.project(
            occurrence: occurrence,
            events: [
              factory.taken(
                occurrence: occurrence,
                eventId: _eventId(instant.minute + 1),
                occurredAtUtc: instant,
                recordedAtUtc: instant,
                actor: AdherenceEventActor.user,
              ),
            ],
            evaluatedAtUtc: occurrence.currentWindow.windowEndsAt,
          );
      expect(
        projectionAt(
          occurrence.currentWindow.windowStartsAt.subtract(
            const Duration(microseconds: 1),
          ),
        ).state,
        OccurrenceAdherenceState.takenEarly,
      );
      expect(
        projectionAt(occurrence.currentWindow.windowStartsAt).state,
        OccurrenceAdherenceState.takenOnTime,
      );
      expect(
        projectionAt(occurrence.currentWindow.onTimeEndsAt).state,
        OccurrenceAdherenceState.takenOnTime,
      );
      expect(
        projectionAt(
          occurrence.currentWindow.onTimeEndsAt.add(
            const Duration(microseconds: 1),
          ),
        ).state,
        OccurrenceAdherenceState.takenLate,
      );
      expect(
        projectionAt(occurrence.currentWindow.windowEndsAt).state,
        OccurrenceAdherenceState.takenLate,
      );
    });

    test('taken and skipped are terminal and input order is irrelevant', () {
      final occurrence = _occurrence();
      final taken = factory.taken(
        occurrence: occurrence,
        eventId: _eventId(1),
        occurredAtUtc: _target,
        recordedAtUtc: _target,
        actor: AdherenceEventActor.user,
      );
      final first = projector.project(
        occurrence: occurrence,
        events: [taken],
        evaluatedAtUtc: _target.add(const Duration(days: 1)),
      );
      expect(first.state, OccurrenceAdherenceState.takenOnTime);
      final skipped = factory.skipped(
        occurrence: occurrence,
        eventId: _eventId(2),
        occurredAtUtc: _target,
        recordedAtUtc: _target,
        actor: AdherenceEventActor.user,
      );
      final conflictA = projector.project(
        occurrence: occurrence,
        events: [taken, skipped],
        evaluatedAtUtc: _target.add(const Duration(days: 1)),
      );
      final conflictB = projector.project(
        occurrence: occurrence,
        events: [skipped, taken],
        evaluatedAtUtc: _target.add(const Duration(days: 1)),
      );
      expect(conflictA.state, OccurrenceAdherenceState.inconsistent);
      expect(conflictB.state, conflictA.state);
    });

    test('correction replaces a fact without mutating history', () {
      final occurrence = _occurrence();
      final skipped = factory.skipped(
        occurrence: occurrence,
        eventId: _eventId(1),
        occurredAtUtc: _target,
        recordedAtUtc: _target,
        actor: AdherenceEventActor.user,
      );
      final correction = factory.correction(
        occurrence: occurrence,
        eventId: _eventId(2),
        referencedEvent: skipped,
        action: AdherenceCorrectionAction.replace,
        replacementType: AdherenceEventType.taken,
        replacementOccurredAtUtc: _target.add(const Duration(hours: 2)),
        occurredAtUtc: _target.add(const Duration(hours: 3)),
        recordedAtUtc: _target.add(const Duration(hours: 3)),
        actor: AdherenceEventActor.user,
      );
      final result = projector.project(
        occurrence: occurrence,
        events: [correction, skipped],
        evaluatedAtUtc: _target.add(const Duration(days: 1)),
      );
      expect(result.state, OccurrenceAdherenceState.takenLate);
      expect(result.supersededEvents, contains(skipped));
      expect(skipped.type, AdherenceEventType.skipped);
      expect(result.effectiveEvent, correction);
    });

    test('missing references, cycles and concurrent corrections conflict', () {
      final occurrence = _occurrence();
      RoutineAdherenceEvent correction(int id, int reference) =>
          RoutineAdherenceEvent(
            eventId: _eventId(id),
            occurrenceId: occurrence.occurrenceId,
            routineId: occurrence.routineId,
            planId: occurrence.planId,
            scheduleId: occurrence.scheduleId,
            type: AdherenceEventType.correction,
            occurredAtUtc: _target,
            recordedAtUtc: _target,
            actor: AdherenceEventActor.user,
            referencedEventId: _eventId(reference),
            correctionAction: AdherenceCorrectionAction.invalidate,
          );
      final missing = projector.project(
        occurrence: occurrence,
        events: [correction(1, 9)],
        evaluatedAtUtc: _target,
      );
      final cycle = projector.project(
        occurrence: occurrence,
        events: [correction(1, 2), correction(2, 1)],
        evaluatedAtUtc: _target,
      );
      expect(missing.state, OccurrenceAdherenceState.inconsistent);
      expect(
        missing.diagnostics,
        contains(AdherenceProjectionDiagnostic.missingCorrectionReference),
      );
      expect(cycle.state, OccurrenceAdherenceState.inconsistent);
      expect(
        cycle.diagnostics,
        contains(AdherenceProjectionDiagnostic.correctionCycle),
      );
    });

    test('reschedule uses latest window and pause excludes defensively', () {
      final original = _occurrence();
      final newWindow = _window(_target.add(const Duration(hours: 2)));
      final rescheduledOccurrence = original.reschedule(newWindow);
      final event = factory.rescheduled(
        occurrence: original,
        eventId: _eventId(1),
        occurredAtUtc: _target.subtract(const Duration(hours: 1)),
        recordedAtUtc: _target.subtract(const Duration(hours: 1)),
        actor: AdherenceEventActor.user,
        newWindow: newWindow,
      );
      final pending = projector.project(
        occurrence: rescheduledOccurrence,
        events: [event],
        evaluatedAtUtc: newWindow.scheduledFor,
      );
      expect(pending.effectiveWindow, newWindow);
      expect(rescheduledOccurrence.originalScheduledFor, _target);
      final paused = projector.project(
        occurrence: original,
        events: const [],
        evaluatedAtUtc: _target.add(const Duration(days: 1)),
        pauses: [_pause()],
      );
      expect(paused.state, OccurrenceAdherenceState.notApplicable);
      expect(paused.isExcluded, isTrue);
    });

    test(
      'PRN without use is not pending or missed; taken remains separate',
      () {
        final prn = _occurrence(prn: true);
        final empty = projector.project(
          occurrence: prn,
          events: const [],
          evaluatedAtUtc: _target.add(const Duration(days: 1)),
        );
        final event = factory.taken(
          occurrence: prn,
          eventId: _eventId(1),
          occurredAtUtc: _target,
          recordedAtUtc: _target,
          actor: AdherenceEventActor.user,
        );
        final used = projector.project(
          occurrence: prn,
          events: [event],
          evaluatedAtUtc: _target,
        );
        expect(empty.state, OccurrenceAdherenceState.notApplicable);
        expect(used.state, OccurrenceAdherenceState.takenOnTime);
        final metrics = const AdherenceCalculator().calculate([empty, used]);
        expect(metrics.denominator, 0);
        expect(metrics.prnTakenCount, 1);
        expect(metrics.adherenceRate, isNull);
      },
    );
  });

  group('metrics and aggregation', () {
    test('strict adherence, completion and coverage use distinct formulas', () {
      final occurrences = List.generate(
        5,
        (index) => _occurrence(
          id: _occurrenceId(index + 1),
          target: _target.add(Duration(days: index)),
        ),
      );
      final projections = <RoutineAdherenceProjection>[
        _projectTaken(occurrences[0], _target),
        _projectTaken(
          occurrences[1],
          occurrences[1].currentScheduledFor.add(const Duration(hours: 2)),
        ),
        projector.project(
          occurrence: occurrences[2],
          events: [
            factory.skipped(
              occurrence: occurrences[2],
              eventId: _eventId(30),
              occurredAtUtc: occurrences[2].currentScheduledFor,
              recordedAtUtc: occurrences[2].currentScheduledFor,
              actor: AdherenceEventActor.user,
            ),
          ],
          evaluatedAtUtc: _target.add(const Duration(days: 10)),
        ),
        projector.project(
          occurrence: occurrences[3],
          events: const [],
          evaluatedAtUtc: _target.add(const Duration(days: 10)),
        ),
        projector.project(
          occurrence: occurrences[4],
          events: const [],
          evaluatedAtUtc: occurrences[4].currentScheduledFor,
        ),
      ];
      final result = const AdherenceCalculator().calculate(projections);
      expect(result.denominator, 4);
      expect(result.adherentCount, 1);
      expect(result.completedCount, 2);
      expect(result.adherenceRate, 0.25);
      expect(result.completionRate, 0.5);
      expect(result.pendingCount, 1);
      expect(result.coverage.rate, 1);
    });

    test('empty denominator is unavailable, never artificial zero', () {
      final pending = projector.project(
        occurrence: _occurrence(),
        events: const [],
        evaluatedAtUtc: _target,
      );
      final result = const AdherenceCalculator().calculate([pending]);
      expect(result.state, AdherenceMetricState.unavailable);
      expect(result.adherenceRate, isNull);
      expect(result.completionRate, isNull);
    });

    test('aggregates semi-open period into immutable dimensions', () {
      final first = _occurrence();
      final second = _occurrence(
        id: _occurrenceId2,
        target: _target.add(const Duration(days: 1)),
      );
      final event = factory.taken(
        occurrence: first,
        eventId: _eventId(1),
        occurredAtUtc: _target,
        recordedAtUtc: _target,
        actor: AdherenceEventActor.user,
      );
      final result = const RoutineAdherenceAggregator().aggregate(
        occurrences: [second, first],
        events: [event],
        startInclusiveUtc: _target,
        endExclusiveUtc: _target.add(const Duration(days: 1)),
        evaluatedAtUtc: _target.add(const Duration(days: 2)),
        categoriesByRoutine: {
          RoutineId(_routineId): RoutineCategory.medication,
        },
      );
      expect(result.global.denominator, 1);
      expect(result.byRoutine, hasLength(1));
      expect(result.byCategory, hasLength(1));
      expect(result.byPlan, hasLength(1));
      expect(result.bySchedule, hasLength(1));
      expect(result.byClinicalDay, hasLength(1));
      expect(() => result.byRoutine.clear(), throwsUnsupportedError);
    });
  });

  test(
    'adherence domain has no clock, infrastructure, UUIDv4, or missed event',
    () {
      final files = Directory('lib/features/smart_routines/domain')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));
      const forbidden = [
        'DateTime.now(',
        '.v4(',
        'package:flutter/',
        'riverpod',
        'drift',
        'supabase',
        'local_notifications',
        'AdherenceEventType.missed',
      ];
      for (final file in files) {
        final source = file.readAsStringSync();
        for (final token in forbidden) {
          expect(
            source,
            isNot(contains(token)),
            reason: '${file.path}: $token',
          );
        }
      }
    },
  );
}

RoutineAdherenceProjection _projectTaken(
  RoutineOccurrence occurrence,
  DateTime at,
) {
  final event = const RoutineAdherenceEventFactory().taken(
    occurrence: occurrence,
    eventId: _eventId(at.day + at.hour + at.minute),
    occurredAtUtc: at,
    recordedAtUtc: at,
    actor: AdherenceEventActor.user,
  );
  return const RoutineAdherenceProjector().project(
    occurrence: occurrence,
    events: [event],
    evaluatedAtUtc: at.add(const Duration(days: 20)),
  );
}

RoutineOccurrence _occurrence({
  String id = _occurrenceId1,
  DateTime? target,
  bool prn = false,
}) {
  final effectiveTarget = target ?? _target;
  final window = _window(effectiveTarget);
  return RoutineOccurrence(
    occurrenceId: RoutineOccurrenceId(id),
    routineId: RoutineId(_routineId),
    planId: RoutinePlanId(_planId),
    scheduleId: prn ? null : RoutineScheduleId(_scheduleId),
    origin: prn
        ? RoutineOccurrenceOrigin.adHocAsNeeded
        : RoutineOccurrenceOrigin.generated,
    originalWindow: window,
    currentWindow: window,
    status: RoutineOccurrenceStatus.expected,
    originalClinicalDate: LocalDate.fromDateTime(effectiveTarget),
    originalLocalTime: TimeOfDayValue(
      hour: effectiveTarget.hour,
      minute: effectiveTarget.minute,
    ),
    originalTimeZone: IanaTimeZone('UTC'),
    expectationKind: prn
        ? ExpectationKind.asNeeded
        : ExpectationKind.recurringExpectation,
    sequence: 0,
  );
}

OccurrenceWindow _window(DateTime target) => OccurrenceWindow(
  windowStartsAt: target.subtract(const Duration(minutes: 30)),
  scheduledFor: target,
  onTimeEndsAt: target.add(const Duration(minutes: 30)),
  windowEndsAt: target.add(const Duration(hours: 1)),
);

RoutinePause _pause() => RoutinePause(
  pauseId: RoutinePauseId('00000000-0000-4000-8000-000000000099'),
  routineId: RoutineId(_routineId),
  scope: RoutinePauseScope.routine,
  startsAt: _target.subtract(const Duration(hours: 1)),
  endsAt: _target.add(const Duration(hours: 1)),
  createdAt: _target,
);

RoutineAdherenceEventId _eventId(int value) => RoutineAdherenceEventId(
  '00000000-0000-4000-8000-${value.toString().padLeft(12, '0')}',
);

String _occurrenceId(int value) =>
    '00000000-0000-4000-8001-${value.toString().padLeft(12, '0')}';

final _target = DateTime.utc(2026, 7, 20, 11);
const _routineId = '00000000-0000-4000-8000-000000000001';
const _planId = '00000000-0000-4000-8000-000000000002';
const _scheduleId = '00000000-0000-4000-8000-000000000003';
const _occurrenceId1 = '00000000-0000-4000-8000-000000000004';
const _occurrenceId2 = '00000000-0000-4000-8000-000000000014';
