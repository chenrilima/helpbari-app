import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/smart_routines/domain/smart_routines_domain.dart';

void main() {
  final now = DateTime.utc(2026, 7, 20, 12);

  group('typed identifiers and basic values', () {
    test('accept valid UUIDs, normalize them, and reject invalid values', () {
      expect(RoutineId(_routineUuid.toUpperCase()).value, _routineUuid);
      expect(RoutinePlanId(_planUuid).value, _planUuid);
      expect(RoutineScheduleId(_scheduleUuid).value, _scheduleUuid);
      expect(RoutineOccurrenceId(_occurrenceUuid).value, _occurrenceUuid);
      expect(RoutineAdherenceEventId(_eventUuid).value, _eventUuid);
      expect(RoutinePauseId(_pauseUuid).value, _pauseUuid);
      expect(PrescriptionId(_prescriptionUuid).value, _prescriptionUuid);
      expect(
        PrescriptionItemId(_prescriptionItemUuid).value,
        _prescriptionItemUuid,
      );
      expect(
        () => RoutineId(''),
        throwsA(isA<SmartRoutineValidationException>()),
      );
    });

    test('time validates ranges and parses canonical HH:mm', () {
      expect(TimeOfDayValue(hour: 23, minute: 59).toString(), '23:59');
      expect(TimeOfDayValue.parse('08:05'), TimeOfDayValue(hour: 8, minute: 5));
      expect(
        () => TimeOfDayValue(hour: 24, minute: 0),
        throwsA(isA<SmartRoutineValidationException>()),
      );
      expect(
        () => TimeOfDayValue.parse('8:05'),
        throwsA(isA<SmartRoutineValidationException>()),
      );
    });

    test('weekdays normalize duplicates, sort, and expose immutable data', () {
      final weekdays = WeekdaySet([5, 1, 5, 3]);
      expect(weekdays.values, [1, 3, 5]);
      expect(() => weekdays.values.add(7), throwsUnsupportedError);
      expect(
        () => WeekdaySet([0]),
        throwsA(isA<SmartRoutineValidationException>()),
      );
    });

    test('occurrence window requires chronological ordering', () {
      expect(
        OccurrenceWindow(
          windowStartsAt: now,
          scheduledFor: now.add(const Duration(minutes: 10)),
          windowEndsAt: now.add(const Duration(minutes: 20)),
        ).scheduledFor,
        now.add(const Duration(minutes: 10)),
      );
      expect(
        () => OccurrenceWindow(
          windowStartsAt: now,
          scheduledFor: now.subtract(const Duration(minutes: 1)),
          windowEndsAt: now.add(const Duration(minutes: 20)),
        ),
        throwsA(isA<SmartRoutineValidationException>()),
      );
    });

    test('timezone accepts UTC and structural IANA names', () {
      expect(IanaTimeZone('UTC').value, 'UTC');
      expect(IanaTimeZone('America/Sao_Paulo').value, 'America/Sao_Paulo');
      expect(
        () => IanaTimeZone('São Paulo'),
        throwsA(isA<SmartRoutineValidationException>()),
      );
    });
  });

  group('schedule rules', () {
    final morning = TimeOfDayValue(hour: 8, minute: 0);
    final night = TimeOfDayValue(hour: 20, minute: 0);

    test('time collections are canonical, unique, and immutable', () {
      final rule = DailyAtTimesRule([night, morning, night]);
      expect(rule.times, [morning, night]);
      expect(() => rule.times.add(morning), throwsUnsupportedError);
      expect(
        () => DailyAtTimesRule([]),
        throwsA(isA<SmartRoutineValidationException>()),
      );
    });

    test('specific weekdays require weekdays and times', () {
      expect(
        SpecificWeekdaysAtTimesRule(
          weekdays: WeekdaySet([1, 3]),
          times: [morning],
        ),
        isA<SpecificWeekdaysAtTimesRule>(),
      );
      expect(
        () => SpecificWeekdaysAtTimesRule(
          weekdays: WeekdaySet([]),
          times: [morning],
        ),
        throwsA(isA<SmartRoutineValidationException>()),
      );
      expect(
        () => SpecificWeekdaysAtTimesRule(weekdays: WeekdaySet([1]), times: []),
        throwsA(isA<SmartRoutineValidationException>()),
      );
    });

    test('interval rules require positive intervals', () {
      expect(EveryNHoursRule(6).intervalHours, 6);
      expect(
        () => EveryNHoursRule(0),
        throwsA(isA<SmartRoutineValidationException>()),
      );
      expect(EveryNDaysRule(intervalDays: 2, times: [morning]).intervalDays, 2);
      expect(
        () => EveryNDaysRule(intervalDays: 0, times: [morning]),
        throwsA(isA<SmartRoutineValidationException>()),
      );
    });

    test('weekly, monthly, single, free-form and PRN rules validate', () {
      expect(WeeklyRule(weekday: 1, times: [morning]).weekday, 1);
      expect(
        () => WeeklyRule(weekday: 8, times: [morning]),
        throwsA(isA<SmartRoutineValidationException>()),
      );
      expect(MonthlyRule(dayOfMonth: 31, times: [morning]).dayOfMonth, 31);
      expect(
        () => MonthlyRule(dayOfMonth: 0, times: [morning]),
        throwsA(isA<SmartRoutineValidationException>()),
      );
      expect(SingleDoseRule(now).scheduledAt, now);
      expect(
        FreeFormRule(' conforme orientação ').instructions,
        'conforme orientação',
      );
      expect(
        () => FreeFormRule(' '),
        throwsA(isA<SmartRoutineValidationException>()),
      );
      expect(
        const AsNeededRule().frequencyType,
        ScheduleFrequencyType.asNeeded,
      );
    });
  });

  group('routine and plan lifecycle', () {
    test('routine validates its name and permitted status transitions', () {
      final routine = _routine(now);
      final paused = routine.changeStatus(
        RoutineStatus.paused,
        now.add(const Duration(minutes: 1)),
      );
      final active = paused.changeStatus(
        RoutineStatus.active,
        now.add(const Duration(minutes: 2)),
      );
      final archived = active.changeStatus(
        RoutineStatus.archived,
        now.add(const Duration(minutes: 3)),
      );

      expect(paused.status, RoutineStatus.paused);
      expect(archived.status, RoutineStatus.archived);
      expect(
        () => active.changeStatus(RoutineStatus.active, now),
        returnsNormally,
      );
      expect(
        () => active
            .changeStatus(RoutineStatus.completed, now)
            .changeStatus(RoutineStatus.active, now),
        throwsA(isA<SmartRoutineValidationException>()),
      );
      expect(
        () => SmartRoutine(
          routineId: RoutineId(_routineUuid),
          category: RoutineCategory.medication,
          displayName: ' ',
          status: RoutineStatus.active,
          source: RoutineSource.manual,
          createdAt: now,
          updatedAt: now,
        ),
        throwsA(isA<SmartRoutineValidationException>()),
      );
    });

    test('archived is terminal and cannot restore a functional status', () {
      final archived = _routine(now).changeStatus(
        RoutineStatus.archived,
        now.add(const Duration(minutes: 1)),
      );

      for (final next in [
        RoutineStatus.active,
        RoutineStatus.paused,
        RoutineStatus.completed,
        RoutineStatus.canceled,
      ]) {
        expect(
          () =>
              archived.changeStatus(next, now.add(const Duration(minutes: 2))),
          throwsA(isA<SmartRoutineValidationException>()),
        );
      }
    });

    test(
      'completed and canceled can be archived without changing tombstone',
      () {
        final deletedAt = now.subtract(const Duration(days: 1));
        final routine = _routine(now, deletedAt: deletedAt);

        final completed = routine.changeStatus(RoutineStatus.completed, now);
        final canceled = routine.changeStatus(RoutineStatus.canceled, now);

        expect(
          completed.changeStatus(RoutineStatus.archived, now).status,
          RoutineStatus.archived,
        );
        expect(
          canceled.changeStatus(RoutineStatus.archived, now).status,
          RoutineStatus.archived,
        );
        expect(
          completed.changeStatus(RoutineStatus.archived, now).deletedAt,
          deletedAt,
        );
      },
    );

    test('plan validates revisions, periods, duration semantics and modes', () {
      expect(
        () => _plan(now, revision: 0),
        throwsA(isA<SmartRoutineValidationException>()),
      );
      expect(
        () => _plan(now, durationType: PlanDurationType.fixed),
        throwsA(isA<SmartRoutineValidationException>()),
      );
      expect(
        () => _plan(
          now,
          durationType: PlanDurationType.fixed,
          effectiveUntil: now.subtract(const Duration(days: 1)),
        ),
        throwsA(isA<SmartRoutineValidationException>()),
      );
      expect(_plan(now).durationType, PlanDurationType.unknown);
      expect(
        _plan(now, durationType: PlanDurationType.continuous).durationType,
        PlanDurationType.continuous,
      );
      expect(
        _plan(
          now,
          mode: RoutinePlanMode.asNeeded,
        ).acceptsRule(const AsNeededRule()),
        isTrue,
      );
      expect(_plan(now).acceptsRule(const AsNeededRule()), isFalse);
    });

    test(
      'creating a revision replaces an immutable snapshot and increments revision',
      () {
        final original = _plan(now, activatedAt: now);
        final result = original.createRevision(
          newPlanId: RoutinePlanId(_newPlanUuid),
          at: now.add(const Duration(days: 1)),
        );

        expect(original.replacedAt, isNull);
        expect(result, isA<PlanRevisionResult>());
        expect(result.previousPlan.planId, original.planId);
        expect(
          result.previousPlan.replacedAt,
          now.add(const Duration(days: 1)),
        );
        expect(result.newPlan.planId, RoutinePlanId(_newPlanUuid));
        expect(result.newPlan.routineId, original.routineId);
        expect(result.newPlan.revision, 2);
        expect(result.newPlan.previousPlanId, original.planId);
        expect(result.newPlan.activatedAt, isNull);
        expect(result.newPlan.replacedAt, isNull);
      },
    );

    test(
      'revision preserves previous content and applies changes only to new plan',
      () {
        final original = _plan(
          now,
          activatedAt: now,
          dose: DoseValue(value: '20', unit: 'mg'),
          route: 'oral',
          clinicalInstructions: 'Após o café',
        );
        final result = original.createRevision(
          newPlanId: RoutinePlanId(_newPlanUuid),
          at: now.add(const Duration(days: 1)),
          dose: DoseValue(value: '40', unit: 'mg'),
          route: 'sublingual',
          clinicalInstructions: 'Em jejum',
        );

        expect(result.previousPlan.dose, DoseValue(value: '20', unit: 'mg'));
        expect(result.previousPlan.route, 'oral');
        expect(result.previousPlan.clinicalInstructions, 'Após o café');
        expect(result.previousPlan.effectiveFrom, now);
        expect(result.newPlan.dose, DoseValue(value: '40', unit: 'mg'));
        expect(result.newPlan.route, 'sublingual');
        expect(result.newPlan.clinicalInstructions, 'Em jejum');
        expect(original.replacedAt, isNull);
      },
    );

    test(
      'revision rejects reused identity and invalid replacement lifecycle',
      () {
        final active = _plan(now, activatedAt: now);
        expect(
          () => active.createRevision(
            newPlanId: active.planId,
            at: now.add(const Duration(days: 1)),
          ),
          throwsA(isA<SmartRoutineValidationException>()),
        );
        expect(
          () => _plan(now).createRevision(
            newPlanId: RoutinePlanId(_newPlanUuid),
            at: now.add(const Duration(days: 1)),
          ),
          throwsA(isA<SmartRoutineValidationException>()),
        );
        expect(
          () => _plan(now, replacedAt: now.add(const Duration(hours: 1))),
          throwsA(isA<SmartRoutineValidationException>()),
        );

        final replaced = _plan(
          now,
          activatedAt: now,
          replacedAt: now.add(const Duration(hours: 1)),
        );
        expect(
          () => replaced.createRevision(
            newPlanId: RoutinePlanId(_newPlanUuid),
            at: now.add(const Duration(days: 1)),
          ),
          throwsA(isA<SmartRoutineValidationException>()),
        );
        expect(
          () => _plan(
            now,
            activatedAt: now.add(const Duration(hours: 2)),
            replacedAt: now.add(const Duration(hours: 1)),
          ),
          throwsA(isA<SmartRoutineValidationException>()),
        );
      },
    );

    test('entity and value equality is deterministic', () {
      expect(_routine(now), _routine(now));
      expect(_routine(now).hashCode, _routine(now).hashCode);
      expect(
        DoseValue(value: '1', unit: 'cp'),
        DoseValue(value: '1', unit: 'cp'),
      );
      expect(
        DailyAtTimesRule([TimeOfDayValue(hour: 8, minute: 0)]),
        DailyAtTimesRule([TimeOfDayValue(hour: 8, minute: 0)]),
      );
      final firstRevision = _plan(now, activatedAt: now).createRevision(
        newPlanId: RoutinePlanId(_newPlanUuid),
        at: now.add(const Duration(days: 1)),
      );
      final secondRevision = _plan(now, activatedAt: now).createRevision(
        newPlanId: RoutinePlanId(_newPlanUuid),
        at: now.add(const Duration(days: 1)),
      );
      expect(firstRevision, secondRevision);
      expect(firstRevision.hashCode, secondRevision.hashCode);
    });
  });

  group('schedule, pause, occurrence and adherence', () {
    test('schedule enforces plan mode and non-negative tolerances', () {
      expect(_schedule(now).planId, RoutinePlanId(_planUuid));
      expect(
        () => _schedule(now, plan: _plan(now, mode: RoutinePlanMode.asNeeded)),
        throwsA(isA<SmartRoutineValidationException>()),
      );
      expect(
        () => _schedule(now, earlyTolerance: const Duration(minutes: -1)),
        throwsA(isA<SmartRoutineValidationException>()),
      );
    });

    test(
      'pause supports open/close lifecycle and validates scope and period',
      () {
        final pause = RoutinePause(
          pauseId: RoutinePauseId(_pauseUuid),
          routineId: RoutineId(_routineUuid),
          scope: RoutinePauseScope.routine,
          startsAt: now,
          createdAt: now,
        );
        expect(pause.isOpen, isTrue);
        expect(pause.close(now.add(const Duration(days: 1))).isOpen, isFalse);
        expect(
          () => RoutinePause(
            pauseId: RoutinePauseId(_pauseUuid),
            routineId: RoutineId(_routineUuid),
            scope: RoutinePauseScope.plan,
            startsAt: now,
            createdAt: now,
          ),
          throwsA(isA<SmartRoutineValidationException>()),
        );
        expect(
          () => pause.close(now.subtract(const Duration(seconds: 1))),
          throwsA(isA<SmartRoutineValidationException>()),
        );
      },
    );

    test('rescheduling changes only current window and preserves original', () {
      final originalWindow = _window(now);
      final occurrence = _occurrence(originalWindow);
      final newWindow = _window(now.add(const Duration(hours: 2)));
      final rescheduled = occurrence.reschedule(newWindow);

      expect(rescheduled.originalWindow, same(originalWindow));
      expect(rescheduled.currentWindow, same(newWindow));
      expect(rescheduled.status, RoutineOccurrenceStatus.rescheduled);
      expect(
        () => RoutineOccurrence(
          occurrenceId: RoutineOccurrenceId(_occurrenceUuid),
          routineId: RoutineId(_routineUuid),
          planId: RoutinePlanId(_planUuid),
          origin: RoutineOccurrenceOrigin.generated,
          originalWindow: originalWindow,
          currentWindow: originalWindow,
          status: RoutineOccurrenceStatus.expected,
        ),
        throwsA(isA<SmartRoutineValidationException>()),
      );
    });

    test('corrections reference an event and ordinary events cannot', () {
      final event = _event(now);
      final correction = event.createCorrection(
        correctionId: RoutineAdherenceEventId(_newEventUuid),
        occurredAt: now,
        recordedAt: now,
        createdAt: now,
        actor: AdherenceEventActor.user,
      );
      expect(correction.correctedEventId, event.eventId);
      expect(
        () => RoutineAdherenceEvent(
          eventId: RoutineAdherenceEventId(_newEventUuid),
          occurrenceId: RoutineOccurrenceId(_occurrenceUuid),
          type: AdherenceEventType.taken,
          occurredAt: now,
          recordedAt: now,
          createdAt: now,
          actor: AdherenceEventActor.user,
          correctedEventId: event.eventId,
        ),
        throwsA(isA<SmartRoutineValidationException>()),
      );
      expect(
        () => RoutineAdherenceEvent(
          eventId: RoutineAdherenceEventId(_newEventUuid),
          occurrenceId: RoutineOccurrenceId(_occurrenceUuid),
          type: AdherenceEventType.correction,
          occurredAt: now,
          recordedAt: now,
          createdAt: now,
          actor: AdherenceEventActor.user,
        ),
        throwsA(isA<SmartRoutineValidationException>()),
      );
    });
  });

  test('domain source has no infrastructure or presentation imports', () {
    final files = Directory('lib/features/smart_routines/domain')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    const forbidden = [
      'package:flutter/',
      'drift',
      'supabase',
      'riverpod',
      'local_notifications',
    ];
    for (final file in files) {
      final source = file.readAsStringSync();
      for (final token in forbidden) {
        expect(
          source,
          isNot(contains(token)),
          reason: '${file.path} imports $token',
        );
      }
    }
  });
}

SmartRoutine _routine(DateTime now, {DateTime? deletedAt}) => SmartRoutine(
  routineId: RoutineId(_routineUuid),
  category: RoutineCategory.medication,
  displayName: 'Omeprazol',
  status: RoutineStatus.active,
  source: RoutineSource.manual,
  createdAt: now,
  updatedAt: now,
  deletedAt: deletedAt,
);

RoutinePlan _plan(
  DateTime now, {
  int revision = 1,
  RoutinePlanMode mode = RoutinePlanMode.scheduled,
  PlanDurationType durationType = PlanDurationType.unknown,
  DateTime? effectiveUntil,
  DateTime? activatedAt,
  DateTime? replacedAt,
  DoseValue? dose,
  String? route,
  String? clinicalInstructions,
}) => RoutinePlan(
  planId: RoutinePlanId(_planUuid),
  routineId: RoutineId(_routineUuid),
  revision: revision,
  mode: mode,
  durationType: durationType,
  effectiveFrom: now,
  effectiveUntil: effectiveUntil,
  createdAt: now,
  activatedAt: activatedAt,
  replacedAt: replacedAt,
  dose: dose,
  route: route,
  clinicalInstructions: clinicalInstructions,
);

RoutineSchedule _schedule(
  DateTime now, {
  RoutinePlan? plan,
  Duration earlyTolerance = Duration.zero,
}) => RoutineSchedule(
  scheduleId: RoutineScheduleId(_scheduleUuid),
  plan: plan ?? _plan(now),
  rule: DailyAtTimesRule([TimeOfDayValue(hour: 8, minute: 0)]),
  timeZone: IanaTimeZone('America/Sao_Paulo'),
  reminderPreference: RoutineReminderPreference.enabled,
  earlyTolerance: earlyTolerance,
  onTimeTolerance: Duration.zero,
  lateTolerance: Duration.zero,
  isEnabled: true,
  displayOrder: 0,
);

OccurrenceWindow _window(DateTime scheduledFor) => OccurrenceWindow(
  windowStartsAt: scheduledFor.subtract(const Duration(minutes: 30)),
  scheduledFor: scheduledFor,
  windowEndsAt: scheduledFor.add(const Duration(minutes: 30)),
);

RoutineOccurrence _occurrence(OccurrenceWindow window) => RoutineOccurrence(
  occurrenceId: RoutineOccurrenceId(_occurrenceUuid),
  routineId: RoutineId(_routineUuid),
  planId: RoutinePlanId(_planUuid),
  scheduleId: RoutineScheduleId(_scheduleUuid),
  origin: RoutineOccurrenceOrigin.generated,
  originalWindow: window,
  currentWindow: window,
  status: RoutineOccurrenceStatus.expected,
);

RoutineAdherenceEvent _event(DateTime now) => RoutineAdherenceEvent(
  eventId: RoutineAdherenceEventId(_eventUuid),
  occurrenceId: RoutineOccurrenceId(_occurrenceUuid),
  type: AdherenceEventType.taken,
  occurredAt: now,
  recordedAt: now,
  createdAt: now,
  actor: AdherenceEventActor.user,
);

const _routineUuid = '00000000-0000-4000-8000-000000000001';
const _planUuid = '00000000-0000-4000-8000-000000000002';
const _scheduleUuid = '00000000-0000-4000-8000-000000000003';
const _occurrenceUuid = '00000000-0000-4000-8000-000000000004';
const _eventUuid = '00000000-0000-4000-8000-000000000005';
const _pauseUuid = '00000000-0000-4000-8000-000000000006';
const _prescriptionUuid = '00000000-0000-4000-8000-000000000007';
const _prescriptionItemUuid = '00000000-0000-4000-8000-000000000008';
const _newPlanUuid = '00000000-0000-4000-8000-000000000009';
const _newEventUuid = '00000000-0000-4000-8000-00000000000a';
