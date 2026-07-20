import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/smart_routines/domain/smart_routines_domain.dart';
import 'package:timezone/data/latest.dart' as tz_data;

void main() {
  setUpAll(tz_data.initializeTimeZones);

  group('IANA and DST resolution', () {
    const resolver = ScheduleInstantResolver();

    test('resolves common wall time using the explicit schedule timezone', () {
      final saoPaulo = resolver.resolve(
        localDate: _date,
        localTime: _time(8),
        timeZone: IanaTimeZone('America/Sao_Paulo'),
      );
      final utc = resolver.resolve(
        localDate: _date,
        localTime: _time(8),
        timeZone: IanaTimeZone('UTC'),
      );

      expect(saoPaulo.value!.instantUtc, DateTime.utc(2026, 7, 20, 11));
      expect(utc.value!.instantUtc, DateTime.utc(2026, 7, 20, 8));
      expect(saoPaulo.value!.requestedTime, _time(8));
      expect(
        resolver
            .resolve(
              localDate: _date,
              localTime: _time(8),
              timeZone: IanaTimeZone('America/Sao_Paulo'),
            )
            .value!
            .instantUtc,
        saoPaulo.value!.instantUtc,
      );
    });

    test('invalid timezone is a nominal failure', () {
      final result = resolver.resolve(
        localDate: _date,
        localTime: _time(8),
        timeZone: IanaTimeZone('Invalid/Zone'),
      );
      expect(result.failure, ScheduleInstantResolutionFailure.invalidTimeZone);
    });

    test('gap shifts to first valid minute and can be rejected', () {
      final date = LocalDate(year: 2026, month: 3, day: 8);
      final shifted = resolver.resolve(
        localDate: date,
        localTime: _time(2, 30),
        timeZone: IanaTimeZone('America/New_York'),
      );
      expect(
        shifted.value!.state,
        ScheduleInstantResolutionState.shiftedForward,
      );
      expect(shifted.value!.requestedTime, _time(2, 30));
      expect(shifted.value!.resolvedTime, _time(3));

      final rejected = resolver.resolve(
        localDate: date,
        localTime: _time(2, 30),
        timeZone: IanaTimeZone('America/New_York'),
        nonexistentPolicy: NonexistentLocalTimePolicy.reject,
      );
      expect(
        rejected.failure,
        ScheduleInstantResolutionFailure.nonexistentLocalTimeRejected,
      );
    });

    test('overlap chooses one earlier instant and marks ambiguity', () {
      final date = LocalDate(year: 2026, month: 11, day: 1);
      final result = resolver.resolve(
        localDate: date,
        localTime: _time(1, 30),
        timeZone: IanaTimeZone('America/New_York'),
      );
      expect(
        result.value!.state,
        ScheduleInstantResolutionState.ambiguousEarlierOffset,
      );
      expect(result.value!.instantUtc, DateTime.utc(2026, 11, 1, 5, 30));
    });
  });

  group('window, identity and materialization', () {
    test('window is UTC, explicit, structural and end-exclusive', () {
      final definition = OccurrenceWindowDefinition(
        earlyTolerance: const Duration(minutes: 15),
        onTimeTolerance: const Duration(minutes: 30),
        lateTolerance: const Duration(hours: 2),
      );
      final target = DateTime.utc(2026, 7, 20, 11);
      final window = const OccurrenceWindowResolver().resolve(
        targetAtUtc: target,
        definition: definition,
      );
      expect(window.windowStartsAt, DateTime.utc(2026, 7, 20, 10, 45));
      expect(window.scheduledFor, target);
      expect(window.onTimeEndsAt, DateTime.utc(2026, 7, 20, 11, 30));
      expect(window.windowEndsAt, DateTime.utc(2026, 7, 20, 13));
      expect(
        () => OccurrenceWindowDefinition(
          earlyTolerance: const Duration(minutes: -1),
          onTimeTolerance: Duration.zero,
          lateTolerance: const Duration(hours: 1),
        ),
        throwsA(isA<SmartRoutineValidationException>()),
      );
    });

    test('UUIDv5 canonical contract is stable and ignores display order', () {
      const identity = RoutineOccurrenceIdentityGenerator();
      final first = _blueprint();
      final reordered = _blueprint(displayOrder: 99);
      expect(
        identity.canonicalName(first),
        'v1|routine:00000000-0000-4000-8000-000000000001|plan:00000000-0000-4000-8000-000000000002|schedule:00000000-0000-4000-8000-000000000003|date:2026-07-20|time:08:00:00|tz:America/Sao_Paulo|seq:0',
      );
      expect(identity.generate(first), identity.generate(reordered));
      expect(
        identity.generate(first).value,
        '20296740-95e1-51c2-8022-53fb13fd86b4',
      );
    });

    test(
      'materializes metadata and reschedule preserves original identity',
      () {
        final result = const RoutineOccurrenceMaterializer().materialize(
          blueprint: _blueprint(),
          windowDefinition: _windowDefinition,
        );
        expect(result.isMaterialized, isTrue);
        final occurrence = result.occurrence!;
        expect(occurrence.originalScheduledFor, DateTime.utc(2026, 7, 20, 11));
        expect(occurrence.currentScheduledFor, occurrence.originalScheduledFor);
        expect(occurrence.originalTimeZone, IanaTimeZone('America/Sao_Paulo'));
        expect(occurrence.sequence, 0);
        final newWindow = const OccurrenceWindowResolver().resolve(
          targetAtUtc: DateTime.utc(2026, 7, 20, 13),
          definition: _windowDefinition,
        );
        final rescheduled = occurrence.reschedule(newWindow);
        expect(rescheduled.occurrenceId, occurrence.occurrenceId);
        expect(
          rescheduled.originalScheduledFor,
          occurrence.originalScheduledFor,
        );
        expect(rescheduled.currentScheduledFor, DateTime.utc(2026, 7, 20, 13));
      },
    );
  });

  group('generation', () {
    test('daily generation is repeatable and uses distinct schedule IDs', () {
      final plan = _plan();
      final result = const RoutineOccurrenceGenerator().generate(
        routine: _routine(),
        plans: [plan],
        schedules: [
          _schedule(plan, _scheduleId, DailyAtTimesRule([_time(8)])),
          _schedule(plan, _scheduleId2, DailyAtTimesRule([_time(8)])),
        ],
        pauses: const [],
        clinicalDate: _date,
        operationalAt: DateTime.utc(2026, 7, 20, 12),
      );
      expect(result.occurrences, hasLength(2));
      expect(
        result.occurrences.map((item) => item.occurrenceId).toSet(),
        hasLength(2),
      );
      expect(
        result.occurrences,
        List.of(result.occurrences)..sort(
          (a, b) => a.originalScheduledFor.compareTo(b.originalScheduledFor),
        ),
      );
    });

    test('every-hours keeps absolute cadence and semi-open boundaries', () {
      final plan = _plan();
      final schedule = _schedule(
        plan,
        _scheduleId,
        EveryNHoursRule(8, anchorAtUtc: DateTime.utc(2026, 10, 31, 5)),
        zone: 'America/New_York',
      );
      final generator = const EveryNHoursOccurrenceGenerator();
      final firstPage = generator.generate(
        routine: _routine(),
        plans: [plan],
        schedules: [schedule],
        pauses: const [],
        startInstantInclusive: DateTime.utc(2026, 10, 31, 5),
        endInstantExclusive: DateTime.utc(2026, 11, 1, 5),
        maxOccurrences: 3,
      );
      final secondPage = generator.generate(
        routine: _routine(),
        plans: [plan],
        schedules: [schedule],
        pauses: const [],
        startInstantInclusive: DateTime.utc(2026, 11, 1, 5),
        endInstantExclusive: DateTime.utc(2026, 11, 2, 5),
        maxOccurrences: 3,
      );
      expect(firstPage.occurrences, hasLength(3));
      expect(secondPage.occurrences, hasLength(3));
      expect(
        firstPage.occurrences.last.originalScheduledFor.difference(
          firstPage.occurrences.first.originalScheduledFor,
        ),
        const Duration(hours: 16),
      );
      expect(
        firstPage.occurrences
            .map((e) => e.occurrenceId)
            .toSet()
            .intersection(
              secondPage.occurrences.map((e) => e.occurrenceId).toSet(),
            ),
        isEmpty,
      );
    });
  });
}

OccurrenceBlueprint _blueprint({int displayOrder = 0}) => OccurrenceBlueprint(
  routineId: RoutineId(_routineId),
  planId: RoutinePlanId(_planId),
  scheduleId: RoutineScheduleId(_scheduleId),
  clinicalDate: _date,
  localTime: _time(8),
  timeZone: IanaTimeZone('America/Sao_Paulo'),
  expectationKind: ExpectationKind.recurringExpectation,
  sequence: 0,
  originalLocalDate: _date,
  originalLocalTime: _time(8),
  sourceRuleType: ScheduleFrequencyType.dailyAtTimes,
  scheduleDisplayOrder: displayOrder,
);

SmartRoutine _routine() => SmartRoutine(
  routineId: RoutineId(_routineId),
  category: RoutineCategory.medication,
  displayName: 'Routine',
  status: RoutineStatus.active,
  source: RoutineSource.manual,
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
);

RoutinePlan _plan() => RoutinePlan(
  planId: RoutinePlanId(_planId),
  routineId: RoutineId(_routineId),
  revision: 1,
  mode: RoutinePlanMode.scheduled,
  durationType: PlanDurationType.continuous,
  effectiveFrom: LocalDate(year: 2026, month: 1, day: 1),
  createdAt: DateTime.utc(2026, 1, 1),
  activatedAt: DateTime.utc(2026, 1, 1),
);

RoutineSchedule _schedule(
  RoutinePlan plan,
  String id,
  ScheduleRule rule, {
  String zone = 'America/Sao_Paulo',
}) => RoutineSchedule(
  scheduleId: RoutineScheduleId(id),
  plan: plan,
  rule: rule,
  timeZone: IanaTimeZone(zone),
  reminderPreference: RoutineReminderPreference.disabled,
  earlyTolerance: _windowDefinition.earlyTolerance,
  onTimeTolerance: _windowDefinition.onTimeTolerance,
  lateTolerance: _windowDefinition.lateTolerance,
  isEnabled: true,
  displayOrder: 0,
);

TimeOfDayValue _time(int hour, [int minute = 0]) =>
    TimeOfDayValue(hour: hour, minute: minute);

final _date = LocalDate(year: 2026, month: 7, day: 20);
final _windowDefinition = OccurrenceWindowDefinition(
  earlyTolerance: Duration.zero,
  onTimeTolerance: const Duration(minutes: 30),
  lateTolerance: const Duration(hours: 12),
);
const _routineId = '00000000-0000-4000-8000-000000000001';
const _planId = '00000000-0000-4000-8000-000000000002';
const _scheduleId = '00000000-0000-4000-8000-000000000003';
const _scheduleId2 = '00000000-0000-4000-8000-000000000004';
