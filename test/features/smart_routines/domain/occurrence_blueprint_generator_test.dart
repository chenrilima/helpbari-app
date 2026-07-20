import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/smart_routines/domain/smart_routines_domain.dart';

void main() {
  final monday = LocalDate(year: 2026, month: 7, day: 20);
  final tuesday = LocalDate(year: 2026, month: 7, day: 21);
  final operationalAt = DateTime.utc(2026, 7, 20, 12);
  final morning = TimeOfDayValue(hour: 8, minute: 0);
  final night = TimeOfDayValue(hour: 20, minute: 0);
  const generator = OccurrenceBlueprintGenerator();

  group('OccurrenceBlueprint', () {
    test('preserves local intent and has deterministic logical identity', () {
      final first = _blueprint(monday, morning);
      final second = _blueprint(monday, morning);

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first.logicalKey, second.logicalKey);
      expect(first.timeZone, IanaTimeZone('America/Sao_Paulo'));
      expect(first.originalLocalDate, monday);
      expect(first.originalLocalTime, morning);
    });

    test('rejects negative sequence and non-structured expectation kinds', () {
      expect(
        () => _blueprint(monday, morning, sequence: -1),
        throwsA(isA<SmartRoutineValidationException>()),
      );
      expect(
        () => _blueprint(
          monday,
          morning,
          expectationKind: ExpectationKind.asNeeded,
        ),
        throwsA(isA<SmartRoutineValidationException>()),
      );
    });

    test('requires typed IDs and contains no persistence or UTC fields', () {
      expect(
        () => RoutineId(''),
        throwsA(isA<SmartRoutineValidationException>()),
      );
      expect(
        () => RoutinePlanId(''),
        throwsA(isA<SmartRoutineValidationException>()),
      );
      expect(
        () => RoutineScheduleId(''),
        throwsA(isA<SmartRoutineValidationException>()),
      );
      final source = File(
        'lib/features/smart_routines/domain/value_objects/occurrence_blueprint.dart',
      ).readAsStringSync();
      for (final forbidden in [
        'RoutineOccurrenceId',
        'scheduledFor',
        'windowStartsAt',
        'windowEndsAt',
        'syncStatus',
        'createdAt',
        'updatedAt',
      ]) {
        expect(source, isNot(contains(forbidden)));
      }
    });
  });

  group('daily and calendar rules', () {
    test(
      'daily normalizes times, assigns zero-based sequence, and is stable',
      () {
        final plan = _plan(activatedAt: operationalAt);
        final schedule = _schedule(
          plan: plan,
          rule: DailyAtTimesRule([night, morning, night]),
        );
        final first = _generate(
          generator,
          date: monday,
          at: operationalAt,
          plans: [plan],
          schedules: [schedule],
        );
        final second = _generate(
          generator,
          date: monday,
          at: operationalAt,
          plans: [plan],
          schedules: [schedule],
        );

        expect(first.status, OccurrenceBlueprintGenerationStatus.generated);
        expect(first.blueprints.map((value) => value.localTime), [
          morning,
          night,
        ]);
        expect(first.blueprints.map((value) => value.sequence), [0, 1]);
        expect(first, second);
        expect(
          () => first.blueprints.add(first.blueprints.first),
          throwsUnsupportedError,
        );
      },
    );

    test('specific weekdays and weekly generate only on their ISO weekday', () {
      final plan = _plan(activatedAt: operationalAt);
      final specific = _schedule(
        plan: plan,
        rule: SpecificWeekdaysAtTimesRule(
          weekdays: WeekdaySet([DateTime.monday]),
          times: [morning],
        ),
      );
      final weekly = _schedule(
        id: _schedule2,
        plan: plan,
        rule: WeeklyRule(weekday: DateTime.monday, times: [night]),
      );

      expect(
        _generate(
          generator,
          date: monday,
          at: operationalAt,
          plans: [plan],
          schedules: [specific, weekly],
        ).blueprints.length,
        2,
      );
      expect(
        _generate(
          generator,
          date: tuesday,
          at: operationalAt,
          plans: [plan],
          schedules: [specific, weekly],
        ).status,
        OccurrenceBlueprintGenerationStatus.noEligibleSchedules,
      );
    });

    test('every N days uses its persisted anchor deterministically', () {
      final plan = _plan(activatedAt: operationalAt);
      final schedule = _schedule(
        plan: plan,
        rule: EveryNDaysRule(
          intervalDays: 2,
          anchorDate: monday,
          times: [morning],
        ),
      );
      final wednesday = LocalDate(year: 2026, month: 7, day: 22);
      final sunday = LocalDate(year: 2026, month: 7, day: 19);

      expect(
        _generate(
          generator,
          date: monday,
          at: operationalAt,
          plans: [plan],
          schedules: [schedule],
        ).blueprints.length,
        1,
      );
      expect(
        _generate(
          generator,
          date: wednesday,
          at: operationalAt,
          plans: [plan],
          schedules: [schedule],
        ).blueprints.length,
        1,
      );
      expect(
        _generate(
          generator,
          date: tuesday,
          at: operationalAt,
          plans: [plan],
          schedules: [schedule],
        ).blueprints,
        isEmpty,
      );
      expect(
        _generate(
          generator,
          date: sunday,
          at: operationalAt,
          plans: [plan],
          schedules: [schedule],
        ).blueprints,
        isEmpty,
      );
    });

    test('monthly skips short month without anticipation or postponement', () {
      final plan = _plan(activatedAt: DateTime.utc(2026, 4, 1));
      final schedule = _schedule(
        plan: plan,
        rule: MonthlyRule(dayOfMonth: 31, times: [morning]),
      );
      final april30 = LocalDate(year: 2026, month: 4, day: 30);
      final may1 = LocalDate(year: 2026, month: 5, day: 1);
      final may31 = LocalDate(year: 2026, month: 5, day: 31);

      expect(
        _generate(
          generator,
          date: april30,
          at: DateTime.utc(2026, 4, 30),
          plans: [plan],
          schedules: [schedule],
        ).status,
        OccurrenceBlueprintGenerationStatus.noEligibleSchedules,
      );
      expect(
        _generate(
          generator,
          date: may1,
          at: DateTime.utc(2026, 5, 1),
          plans: [plan],
          schedules: [schedule],
        ).blueprints,
        isEmpty,
      );
      expect(
        _generate(
          generator,
          date: may31,
          at: DateTime.utc(2026, 5, 31),
          plans: [plan],
          schedules: [schedule],
        ).blueprints.length,
        1,
      );
    });

    test(
      'single dose produces exactly one blueprint only on its local date',
      () {
        final plan = _plan(activatedAt: operationalAt);
        final schedule = _schedule(
          plan: plan,
          rule: SingleDoseRule(DateTime(2026, 7, 20, 14, 30)),
        );
        final correct = _generate(
          generator,
          date: monday,
          at: operationalAt,
          plans: [plan],
          schedules: [schedule],
        );
        expect(
          correct.blueprints.single.localTime,
          TimeOfDayValue(hour: 14, minute: 30),
        );
        expect(
          _generate(
            generator,
            date: tuesday,
            at: operationalAt,
            plans: [plan],
            schedules: [schedule],
          ).blueprints,
          isEmpty,
        );
      },
    );
  });

  group('non-obligatory and unsupported rules', () {
    test(
      'PRN, free form, and every N hours preserve distinct empty reasons',
      () {
        final scheduled = _plan(activatedAt: operationalAt);
        final prn = _plan(
          mode: RoutinePlanMode.asNeeded,
          activatedAt: operationalAt,
        );
        expect(
          _generate(
            generator,
            date: monday,
            at: operationalAt,
            plans: [prn],
            schedules: [_schedule(plan: prn, rule: const AsNeededRule())],
          ).status,
          OccurrenceBlueprintGenerationStatus.asNeededOnly,
        );
        expect(
          _generate(
            generator,
            date: monday,
            at: operationalAt,
            plans: [scheduled],
            schedules: [
              _schedule(plan: scheduled, rule: FreeFormRule('texto')),
            ],
          ).status,
          OccurrenceBlueprintGenerationStatus.unstructuredOnly,
        );
        final temporal = _generate(
          generator,
          date: monday,
          at: operationalAt,
          plans: [scheduled],
          schedules: [
            _schedule(
              plan: scheduled,
              rule: EveryNHoursRule(6, anchorAtUtc: DateTime.utc(2026, 7, 20)),
            ),
          ],
        );
        expect(
          temporal.status,
          OccurrenceBlueprintGenerationStatus.requiresInstantEvaluation,
        );
        expect(temporal.blueprints, isEmpty);
      },
    );
  });

  group('routine, plan, pause, and schedule selection', () {
    test('inactive routine statuses and tombstone do not generate', () {
      final plan = _plan(activatedAt: operationalAt);
      final schedule = _schedule(plan: plan, rule: DailyAtTimesRule([morning]));
      for (final status in [
        RoutineStatus.paused,
        RoutineStatus.completed,
        RoutineStatus.canceled,
        RoutineStatus.archived,
      ]) {
        expect(
          _generate(
            generator,
            routine: _routine(status: status),
            date: monday,
            at: operationalAt,
            plans: [plan],
            schedules: [schedule],
          ).status,
          OccurrenceBlueprintGenerationStatus.routineIneligible,
        );
      }
      expect(
        _generate(
          generator,
          routine: _routine(deletedAt: operationalAt),
          date: monday,
          at: operationalAt,
          plans: [plan],
          schedules: [schedule],
        ).status,
        OccurrenceBlueprintGenerationStatus.routineIneligible,
      );
    });

    test('clinical and operational plan boundaries prevent generation', () {
      final future = _plan(effectiveFrom: tuesday, activatedAt: operationalAt);
      final expired = _plan(
        durationType: PlanDurationType.fixed,
        effectiveUntil: LocalDate(year: 2026, month: 7, day: 19),
        activatedAt: operationalAt,
      );
      final inactive = _plan(
        activatedAt: operationalAt.add(const Duration(days: 1)),
      );
      final replaced = _plan(
        activatedAt: operationalAt.subtract(const Duration(days: 1)),
        replacedAt: operationalAt,
      );
      for (final plan in [future, expired, inactive, replaced]) {
        expect(
          _generate(
            generator,
            date: monday,
            at: operationalAt,
            plans: [plan],
            schedules: [
              _schedule(plan: plan, rule: DailyAtTimesRule([morning])),
            ],
          ).status,
          OccurrenceBlueprintGenerationStatus.noValidPlan,
        );
      }
    });

    test(
      'cutover selects only the new revision and never inherits schedules',
      () {
        final previous = _plan(
          activatedAt: operationalAt.subtract(const Duration(days: 10)),
          replacedAt: operationalAt,
        );
        final next = _plan(
          id: _plan2,
          revision: 2,
          previousPlanId: previous.planId,
          activatedAt: operationalAt,
        );
        final oldSchedule = _schedule(
          plan: previous,
          rule: DailyAtTimesRule([morning]),
        );
        final newSchedule = _schedule(
          id: _schedule2,
          plan: next,
          rule: DailyAtTimesRule([night]),
        );
        final result = _generate(
          generator,
          date: monday,
          at: operationalAt,
          plans: [next, previous],
          schedules: [newSchedule, oldSchedule],
        );

        expect(result.selectedPlan, next);
        expect(result.blueprints.single.scheduleId, newSchedule.scheduleId);
        expect(result.ignoredScheduleIds, contains(oldSchedule.scheduleId));
      },
    );

    test('pause uses inclusive start and exclusive end without blueprints', () {
      final plan = _plan(
        activatedAt: operationalAt.subtract(const Duration(days: 1)),
      );
      final schedule = _schedule(plan: plan, rule: DailyAtTimesRule([morning]));
      final pause = _pause(
        startsAt: operationalAt,
        endsAt: operationalAt.add(const Duration(hours: 2)),
      );
      expect(
        _generate(
          generator,
          date: monday,
          at: operationalAt.subtract(const Duration(microseconds: 1)),
          plans: [plan],
          schedules: [schedule],
          pauses: [pause],
        ).blueprints.length,
        1,
      );
      expect(
        _generate(
          generator,
          date: monday,
          at: operationalAt,
          plans: [plan],
          schedules: [schedule],
          pauses: [pause],
        ).status,
        OccurrenceBlueprintGenerationStatus.paused,
      );
      expect(
        _generate(
          generator,
          date: monday,
          at: operationalAt.add(const Duration(hours: 1)),
          plans: [plan],
          schedules: [schedule],
          pauses: [pause],
        ).blueprints,
        isEmpty,
      );
      expect(
        _generate(
          generator,
          date: monday,
          at: operationalAt.add(const Duration(hours: 2)),
          plans: [plan],
          schedules: [schedule],
          pauses: [pause],
        ).blueprints.length,
        1,
      );
    });

    test(
      'foreign pauses are ignored and overlapping applicable pauses are reported',
      () {
        final plan = _plan(
          activatedAt: operationalAt.subtract(const Duration(days: 1)),
        );
        final schedule = _schedule(
          plan: plan,
          rule: DailyAtTimesRule([morning]),
        );
        final foreign = _pause(routineId: _routine2, startsAt: operationalAt);
        expect(
          _generate(
            generator,
            date: monday,
            at: operationalAt,
            plans: [plan],
            schedules: [schedule],
            pauses: [foreign],
          ).blueprints.length,
          1,
        );
        final first = _pause(startsAt: operationalAt);
        final second = _pause(id: _pause2, startsAt: operationalAt);
        final result = _generate(
          generator,
          date: monday,
          at: operationalAt,
          plans: [plan],
          schedules: [schedule],
          pauses: [second, first],
        );
        expect(result.status, OccurrenceBlueprintGenerationStatus.paused);
        expect(
          result.issues,
          contains(OccurrenceBlueprintGenerationIssue.overlappingPauses),
        );
      },
    );

    test(
      'disabled, incompatible, orphan, and missing schedules are explicit',
      () {
        final plan = _plan(activatedAt: operationalAt);
        expect(
          _generate(
            generator,
            date: monday,
            at: operationalAt,
            plans: [plan],
            schedules: const [],
          ).status,
          OccurrenceBlueprintGenerationStatus.noSchedules,
        );
        final disabled = _schedule(
          plan: plan,
          rule: DailyAtTimesRule([morning]),
          enabled: false,
        );
        expect(
          _generate(
            generator,
            date: monday,
            at: operationalAt,
            plans: [plan],
            schedules: [disabled],
          ).status,
          OccurrenceBlueprintGenerationStatus.noEligibleSchedules,
        );

        final prnPlanWithSameId = _plan(mode: RoutinePlanMode.asNeeded);
        final incompatible = _schedule(
          plan: prnPlanWithSameId,
          rule: const AsNeededRule(),
        );
        final incompatibleResult = _generate(
          generator,
          date: monday,
          at: operationalAt,
          plans: [plan],
          schedules: [incompatible],
        );
        expect(
          incompatibleResult.status,
          OccurrenceBlueprintGenerationStatus.inconsistentData,
        );
        expect(
          incompatibleResult.issues,
          contains(OccurrenceBlueprintGenerationIssue.incompatibleSchedule),
        );

        final orphanPlan = _plan(id: _missingPlan);
        final orphan = _schedule(
          plan: orphanPlan,
          rule: DailyAtTimesRule([morning]),
        );
        final valid = _schedule(plan: plan, rule: DailyAtTimesRule([night]));
        final orphanResult = _generate(
          generator,
          date: monday,
          at: operationalAt,
          plans: [plan],
          schedules: [orphan, valid],
        );
        expect(orphanResult.blueprints.length, 1);
        expect(
          orphanResult.issues,
          contains(OccurrenceBlueprintGenerationIssue.orphanSchedule),
        );
      },
    );

    test(
      'two schedules at the same time remain distinct and sort by display order',
      () {
        final plan = _plan(activatedAt: operationalAt);
        final later = _schedule(
          id: _schedule1,
          plan: plan,
          rule: DailyAtTimesRule([morning]),
          order: 2,
        );
        final earlier = _schedule(
          id: _schedule2,
          plan: plan,
          rule: DailyAtTimesRule([morning]),
          order: 1,
        );
        final result = _generate(
          generator,
          date: monday,
          at: operationalAt,
          plans: [plan],
          schedules: [later, earlier],
        );
        expect(result.blueprints.length, 2);
        expect(result.blueprints.map((value) => value.scheduleId), [
          earlier.scheduleId,
          later.scheduleId,
        ]);
      },
    );

    test(
      'no plan, overlapping plans, and input order have deterministic results',
      () {
        expect(
          _generate(
            generator,
            date: monday,
            at: operationalAt,
            plans: const [],
            schedules: const [],
          ).status,
          OccurrenceBlueprintGenerationStatus.noValidPlan,
        );
        final first = _plan(activatedAt: operationalAt);
        final second = _plan(
          id: _plan2,
          revision: 2,
          previousPlanId: first.planId,
          activatedAt: operationalAt,
        );
        expect(
          _generate(
            generator,
            date: monday,
            at: operationalAt,
            plans: [second, first],
            schedules: const [],
          ).status,
          OccurrenceBlueprintGenerationStatus.multipleValidPlans,
        );
        final schedules = [
          _schedule(
            id: _schedule2,
            plan: first,
            rule: DailyAtTimesRule([night]),
          ),
          _schedule(
            id: _schedule1,
            plan: first,
            rule: DailyAtTimesRule([morning]),
          ),
        ];
        final ordered = _generate(
          generator,
          date: monday,
          at: operationalAt,
          plans: [first],
          schedules: schedules,
        );
        final reversed = _generate(
          generator,
          date: monday,
          at: operationalAt,
          plans: [first],
          schedules: schedules.reversed,
        );
        expect(ordered, reversed);
        expect(schedules.length, 2);
      },
    );
  });

  group('clinical range generation', () {
    const rangeGenerator = OccurrenceBlueprintRangeGenerator();
    DateTime instant(LocalDate date) =>
        DateTime.utc(date.year, date.month, date.day, 12);

    test('one and multiple day ranges are semi-open and globally ordered', () {
      final plan = _plan(activatedAt: DateTime.utc(2026, 7, 1));
      final schedule = _schedule(
        plan: plan,
        rule: DailyAtTimesRule([night, morning]),
      );
      final oneDay = rangeGenerator.generate(
        routine: _routine(),
        plans: [plan],
        schedules: [schedule],
        pauses: const [],
        startDate: monday,
        endDateExclusive: tuesday,
        maxDays: 10,
        operationalInstantForDate: instant,
      );
      expect(oneDay.blueprints.length, 2);
      expect(
        oneDay.blueprints.every((value) => value.clinicalDate == monday),
        isTrue,
      );

      final thursday = LocalDate(year: 2026, month: 7, day: 23);
      final multiple = rangeGenerator.generate(
        routine: _routine(),
        plans: [plan],
        schedules: [schedule],
        pauses: const [],
        startDate: monday,
        endDateExclusive: thursday,
        maxDays: 10,
        operationalInstantForDate: instant,
      );
      expect(multiple.blueprints.length, 6);
      expect(
        multiple.blueprints.last.clinicalDate,
        LocalDate(year: 2026, month: 7, day: 22),
      );
      expect(
        List<OccurrenceBlueprint>.of(multiple.blueprints)..sort(),
        multiple.blueprints,
      );
      expect(
        () => multiple.dailyResults.add(oneDay.dailyResults.first),
        throwsUnsupportedError,
      );
    });

    test('empty, inverted, and oversized ranges return explicit states', () {
      OccurrenceBlueprintRangeResult generate(
        LocalDate start,
        LocalDate end,
        int maxDays,
      ) => rangeGenerator.generate(
        routine: _routine(),
        plans: const [],
        schedules: const [],
        pauses: const [],
        startDate: start,
        endDateExclusive: end,
        maxDays: maxDays,
        operationalInstantForDate: instant,
      );
      expect(
        generate(monday, monday, 10).status,
        OccurrenceBlueprintRangeStatus.emptyRange,
      );
      expect(
        generate(tuesday, monday, 10).status,
        OccurrenceBlueprintRangeStatus.invalidRange,
      );
      expect(
        generate(monday, monday.addDays(5), 4).status,
        OccurrenceBlueprintRangeStatus.maxDaysExceeded,
      );
      expect(
        () => generate(monday, tuesday, 0),
        throwsA(isA<SmartRoutineValidationException>()),
      );
    });

    test(
      'range output is independent from input ordering and does not duplicate days',
      () {
        final plan = _plan(activatedAt: DateTime.utc(2026, 7, 1));
        final first = _schedule(
          id: _schedule1,
          plan: plan,
          rule: DailyAtTimesRule([morning]),
        );
        final second = _schedule(
          id: _schedule2,
          plan: plan,
          rule: DailyAtTimesRule([night]),
        );
        OccurrenceBlueprintRangeResult generate(
          Iterable<RoutineSchedule> schedules,
        ) => rangeGenerator.generate(
          routine: _routine(),
          plans: [plan],
          schedules: schedules,
          pauses: const [],
          startDate: monday,
          endDateExclusive: monday.addDays(2),
          maxDays: 2,
          operationalInstantForDate: instant,
        );
        expect(generate([first, second]), generate([second, first]));
        expect(
          generate([
            first,
            second,
          ]).blueprints.map((value) => value.logicalKey).toSet().length,
          4,
        );
      },
    );
  });

  test('blueprint stage stays free from identity and materialization', () {
    final files = <File>[
      File(
        'lib/features/smart_routines/domain/value_objects/occurrence_blueprint.dart',
      ),
      File(
        'lib/features/smart_routines/domain/services/occurrence_blueprint_generator.dart',
      ),
      File(
        'lib/features/smart_routines/domain/services/occurrence_blueprint_range_generator.dart',
      ),
    ];
    const forbidden = [
      'DateTime.now(',
      'UuidService',
      'uuid.v5',
      'package:uuid',
      'package:flutter/',
      'riverpod',
      'drift',
      'supabase',
      'local_notifications',
    ];
    for (final file in files) {
      final source = file.readAsStringSync();
      for (final token in forbidden) {
        expect(source, isNot(contains(token)), reason: '${file.path}: $token');
      }
      expect(source, isNot(contains('RoutineOccurrence(')), reason: file.path);
    }
  });
}

OccurrenceBlueprintGenerationResult _generate(
  OccurrenceBlueprintGenerator generator, {
  SmartRoutine? routine,
  required LocalDate date,
  required DateTime at,
  required Iterable<RoutinePlan> plans,
  required Iterable<RoutineSchedule> schedules,
  Iterable<RoutinePause> pauses = const [],
}) => generator.generate(
  routine: routine ?? _routine(),
  plans: plans,
  schedules: schedules,
  pauses: pauses,
  clinicalDate: date,
  operationalAt: at,
);

OccurrenceBlueprint _blueprint(
  LocalDate date,
  TimeOfDayValue time, {
  int sequence = 0,
  ExpectationKind expectationKind = ExpectationKind.recurringExpectation,
}) => OccurrenceBlueprint(
  routineId: RoutineId(_routine1),
  planId: RoutinePlanId(_plan1),
  scheduleId: RoutineScheduleId(_schedule1),
  clinicalDate: date,
  localTime: time,
  timeZone: IanaTimeZone('America/Sao_Paulo'),
  expectationKind: expectationKind,
  sequence: sequence,
  originalLocalDate: date,
  originalLocalTime: time,
  sourceRuleType: ScheduleFrequencyType.dailyAtTimes,
  scheduleDisplayOrder: 0,
);

SmartRoutine _routine({
  RoutineStatus status = RoutineStatus.active,
  DateTime? deletedAt,
}) => SmartRoutine(
  routineId: RoutineId(_routine1),
  category: RoutineCategory.medication,
  displayName: 'Rotina',
  status: status,
  source: RoutineSource.manual,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  deletedAt: deletedAt,
);

RoutinePlan _plan({
  String id = _plan1,
  int revision = 1,
  RoutinePlanMode mode = RoutinePlanMode.scheduled,
  PlanDurationType durationType = PlanDurationType.unknown,
  LocalDate? effectiveFrom,
  LocalDate? effectiveUntil,
  DateTime? activatedAt,
  DateTime? replacedAt,
  RoutinePlanId? previousPlanId,
}) => RoutinePlan(
  planId: RoutinePlanId(id),
  routineId: RoutineId(_routine1),
  revision: revision,
  mode: mode,
  durationType: durationType,
  effectiveFrom: effectiveFrom ?? LocalDate(year: 2026, month: 1, day: 1),
  effectiveUntil: effectiveUntil,
  createdAt: DateTime.utc(2026),
  activatedAt: activatedAt,
  replacedAt: replacedAt,
  previousPlanId: previousPlanId,
);

RoutineSchedule _schedule({
  String id = _schedule1,
  required RoutinePlan plan,
  required ScheduleRule rule,
  int order = 0,
  bool enabled = true,
}) => RoutineSchedule(
  scheduleId: RoutineScheduleId(id),
  plan: plan,
  rule: rule,
  timeZone: IanaTimeZone('America/Sao_Paulo'),
  reminderPreference: RoutineReminderPreference.enabled,
  earlyTolerance: Duration.zero,
  onTimeTolerance: Duration.zero,
  lateTolerance: Duration.zero,
  isEnabled: enabled,
  displayOrder: order,
);

RoutinePause _pause({
  String id = _pause1,
  String routineId = _routine1,
  required DateTime startsAt,
  DateTime? endsAt,
}) => RoutinePause(
  pauseId: RoutinePauseId(id),
  routineId: RoutineId(routineId),
  scope: RoutinePauseScope.routine,
  startsAt: startsAt,
  endsAt: endsAt,
  createdAt: startsAt,
);

const _routine1 = '50000000-0000-4000-8000-000000000001';
const _routine2 = '50000000-0000-4000-8000-000000000002';
const _plan1 = '60000000-0000-4000-8000-000000000001';
const _plan2 = '60000000-0000-4000-8000-000000000002';
const _missingPlan = '60000000-0000-4000-8000-000000000099';
const _schedule1 = '70000000-0000-4000-8000-000000000001';
const _schedule2 = '70000000-0000-4000-8000-000000000002';
const _pause1 = '80000000-0000-4000-8000-000000000001';
const _pause2 = '80000000-0000-4000-8000-000000000002';
