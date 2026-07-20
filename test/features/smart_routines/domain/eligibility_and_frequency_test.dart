import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/smart_routines/domain/smart_routines_domain.dart';

void main() {
  final start = DateTime.utc(2026, 7, 20, 8);
  final cutover = DateTime.utc(2026, 8, 1, 8);
  final startDate = LocalDate(year: 2026, month: 7, day: 20);
  const validity = PlanValidityPolicy();

  group('plan validity and cutover', () {
    test('effective bounds are inclusive and replacement is exclusive', () {
      final endDate = LocalDate(year: 2026, month: 7, day: 30);
      final plan = _plan(
        activatedAt: start,
        durationType: PlanDurationType.fixed,
        effectiveUntil: endDate,
      );

      expect(
        validity
            .evaluate(
              plan: plan,
              at: start.subtract(const Duration(seconds: 1)),
              clinicalDate: startDate,
            )
            .reason,
        PlanValidityReason.planNotStarted,
      );
      expect(
        validity
            .evaluate(plan: plan, at: start, clinicalDate: startDate)
            .isValid,
        isTrue,
      );
      expect(
        validity
            .evaluate(
              plan: plan,
              at: DateTime.utc(2026, 7, 30, 23, 59, 59),
              clinicalDate: endDate,
            )
            .isValid,
        isTrue,
      );
      expect(
        validity
            .evaluate(
              plan: plan,
              at: DateTime.utc(2026, 7, 31),
              clinicalDate: LocalDate(year: 2026, month: 7, day: 31),
            )
            .reason,
        PlanValidityReason.planExpired,
      );
    });

    test('continuous and unknown remain distinct without an end', () {
      final continuous = _plan(
        activatedAt: start,
        durationType: PlanDurationType.continuous,
      );
      final unknown = _plan(activatedAt: start);
      final future = start.add(const Duration(days: 500));

      final futureDate = LocalDate.fromDateTime(future);
      expect(
        validity
            .evaluate(plan: continuous, at: future, clinicalDate: futureDate)
            .isValid,
        isTrue,
      );
      expect(
        validity
            .evaluate(plan: unknown, at: future, clinicalDate: futureDate)
            .isValid,
        isTrue,
      );
      expect(unknown.durationType, PlanDurationType.unknown);
    });

    test('inactive plan is invalid and cutover has no double validity', () {
      final previous = _plan(activatedAt: start, replacedAt: cutover);
      final next = _plan(
        id: _plan2,
        revision: 2,
        previousPlanId: RoutinePlanId(_plan1),
        effectiveFrom: LocalDate.fromDateTime(cutover),
        activatedAt: cutover,
      );

      expect(
        validity
            .evaluate(plan: _plan(), at: start, clinicalDate: startDate)
            .reason,
        PlanValidityReason.notActivated,
      );
      expect(
        validity
            .evaluate(
              plan: previous,
              at: cutover,
              clinicalDate: LocalDate.fromDateTime(cutover),
            )
            .reason,
        PlanValidityReason.planReplaced,
      );
      expect(
        validity
            .evaluate(
              plan: next,
              at: cutover,
              clinicalDate: LocalDate.fromDateTime(cutover),
            )
            .isValid,
        isTrue,
      );
    });
  });

  group('active plan selection', () {
    const selector = ActivePlanSelector();

    test('selects one valid revision independent of input order', () {
      final previous = _plan(activatedAt: start, replacedAt: cutover);
      final next = _plan(
        id: _plan2,
        revision: 2,
        previousPlanId: RoutinePlanId(_plan1),
        effectiveFrom: LocalDate.fromDateTime(cutover),
        activatedAt: cutover,
      );
      final ordered = selector.select(
        routineId: RoutineId(_routine1),
        plans: [previous, next],
        at: cutover,
        clinicalDate: LocalDate.fromDateTime(cutover),
      );
      final reversed = selector.select(
        routineId: RoutineId(_routine1),
        plans: [next, previous],
        at: cutover,
        clinicalDate: LocalDate.fromDateTime(cutover),
      );

      expect(ordered.reason, PlanSelectionReason.selected);
      expect(ordered.selectedPlan, next);
      expect(reversed, ordered);
    });

    test('reports no valid plan and overlapping valid plans explicitly', () {
      expect(
        selector
            .select(
              routineId: RoutineId(_routine1),
              plans: [_plan()],
              at: start,
              clinicalDate: startDate,
            )
            .reason,
        PlanSelectionReason.noValidPlan,
      );
      final first = _plan(activatedAt: start);
      final second = _plan(
        id: _plan2,
        revision: 2,
        previousPlanId: first.planId,
        activatedAt: start,
      );
      expect(
        selector
            .select(
              routineId: RoutineId(_routine1),
              plans: [second, first],
              at: start,
              clinicalDate: startDate,
            )
            .reason,
        PlanSelectionReason.multipleValidPlans,
      );
    });

    test('detects duplicate revisions, foreign routines and broken chains', () {
      final first = _plan(activatedAt: start);
      expect(
        selector
            .select(
              routineId: RoutineId(_routine1),
              plans: [
                first,
                _plan(id: _plan2, activatedAt: start),
              ],
              at: start,
              clinicalDate: startDate,
            )
            .reason,
        PlanSelectionReason.duplicateRevision,
      );
      expect(
        selector
            .select(
              routineId: RoutineId(_routine1),
              plans: [_plan(routineId: _routine2, activatedAt: start)],
              at: start,
              clinicalDate: startDate,
            )
            .reason,
        PlanSelectionReason.foreignRoutine,
      );
      expect(
        selector
            .select(
              routineId: RoutineId(_routine1),
              plans: [
                first,
                _plan(
                  id: _plan2,
                  revision: 2,
                  previousPlanId: RoutinePlanId(_missingPlan),
                  activatedAt: start,
                ),
              ],
              at: start,
              clinicalDate: startDate,
            )
            .reason,
        PlanSelectionReason.inconsistentChain,
      );
    });
  });

  group('pause and compatibility policies', () {
    test(
      'pause uses [start, end), ignores foreign scopes and detects overlap',
      () {
        const policy = PauseEligibilityPolicy();
        final pause = _pause(startsAt: start, endsAt: cutover);
        final overlap = _pause(
          id: _pause2,
          startsAt: start.add(const Duration(hours: 1)),
        );
        final foreignRoutine = _pause(
          id: _pause3,
          routineId: _routine2,
          startsAt: start,
        );
        final foreignPlan = _pause(
          id: _pause4,
          scope: RoutinePauseScope.plan,
          planId: _plan2,
          startsAt: start,
        );

        expect(
          _pauseEvaluation(policy, [
            pause,
          ], start.subtract(const Duration(seconds: 1))).isPaused,
          isFalse,
        );
        expect(_pauseEvaluation(policy, [pause], start).isPaused, isTrue);
        expect(
          _pauseEvaluation(policy, [
            pause,
          ], start.add(const Duration(days: 1))).isPaused,
          isTrue,
        );
        expect(_pauseEvaluation(policy, [pause], cutover).isPaused, isFalse);
        final result = _pauseEvaluation(policy, [
          foreignRoutine,
          overlap,
          foreignPlan,
          pause,
        ], start.add(const Duration(hours: 2)));
        expect(result.applicablePauses, [pause, overlap]);
        expect(result.hasOverlap, isTrue);
        expect(
          () => result.applicablePauses.add(pause),
          throwsUnsupportedError,
        );
      },
    );

    test('open pause remains applicable', () {
      final result = _pauseEvaluation(const PauseEligibilityPolicy(), [
        _pause(startsAt: start),
      ], start.add(const Duration(days: 100)));
      expect(result.isPaused, isTrue);
    });

    test(
      'compatibility audits plan ID and PRN mode without category coupling',
      () {
        const policy = SchedulePlanCompatibilityPolicy();
        final scheduledPlan = _plan(activatedAt: start);
        final schedule = _schedule(plan: scheduledPlan, rule: _dailyRule());
        expect(
          policy.evaluate(plan: scheduledPlan, schedule: schedule).isCompatible,
          isTrue,
        );
        expect(
          policy
              .evaluate(
                plan: _plan(id: _plan2, activatedAt: start),
                schedule: schedule,
              )
              .reason,
          ScheduleCompatibilityReason.planIdMismatch,
        );

        final prnPlan = _plan(
          mode: RoutinePlanMode.asNeeded,
          activatedAt: start,
        );
        final prnSchedule = _schedule(
          plan: prnPlan,
          rule: const AsNeededRule(),
        );
        expect(
          policy.evaluate(plan: prnPlan, schedule: prnSchedule).isCompatible,
          isTrue,
        );
        final forgedRecurring = _schedule(
          plan: scheduledPlan,
          rule: _dailyRule(),
        );
        expect(
          policy.evaluate(plan: prnPlan, schedule: forgedRecurring).reason,
          ScheduleCompatibilityReason.asNeededPlanWithScheduledRule,
        );
        final forgedPrn = _schedule(
          plan: _plan(mode: RoutinePlanMode.asNeeded),
          rule: const AsNeededRule(),
        );
        expect(
          policy.evaluate(plan: scheduledPlan, schedule: forgedPrn).reason,
          ScheduleCompatibilityReason.scheduledPlanWithAsNeededRule,
        );
      },
    );
  });

  group('date eligibility and local time resolution', () {
    const policy = ScheduleDateEligibilityPolicy();
    const resolver = ScheduleTimesResolver();
    final monday = LocalDate(year: 2026, month: 7, day: 20);
    final tuesday = LocalDate(year: 2026, month: 7, day: 21);
    final morning = TimeOfDayValue(hour: 8, minute: 0);
    final night = TimeOfDayValue(hour: 20, minute: 0);

    test('LocalDate is validated and uses deterministic ISO weekdays', () {
      expect(monday.weekday, DateTime.monday);
      expect(
        () => LocalDate(year: 2026, month: 2, day: 30),
        throwsA(isA<SmartRoutineValidationException>()),
      );
    });

    test('daily and specific weekdays are deterministic', () {
      expect(
        policy.evaluate(rule: _dailyRule(), localDate: monday).isEligible,
        isTrue,
      );
      final weekdays = SpecificWeekdaysAtTimesRule(
        weekdays: WeekdaySet([DateTime.monday]),
        times: [morning],
      );
      expect(
        policy.evaluate(rule: weekdays, localDate: monday).isEligible,
        isTrue,
      );
      expect(
        policy.evaluate(rule: weekdays, localDate: tuesday).isEligible,
        isFalse,
      );
    });

    test('every N days owns a stable anchor and uses non-negative modulo', () {
      final rule = EveryNDaysRule(
        intervalDays: 3,
        anchorDate: monday,
        times: [morning],
      );
      expect(rule.anchorDate, monday);
      expect(policy.evaluate(rule: rule, localDate: monday).isEligible, isTrue);
      expect(
        policy
            .evaluate(
              rule: rule,
              localDate: LocalDate(year: 2026, month: 7, day: 23),
            )
            .isEligible,
        isTrue,
      );
      expect(
        policy.evaluate(rule: rule, localDate: tuesday).isEligible,
        isFalse,
      );
      expect(
        policy
            .evaluate(
              rule: rule,
              localDate: LocalDate(year: 2026, month: 7, day: 19),
            )
            .isEligible,
        isFalse,
      );
      expect(
        EveryNDaysRule(intervalDays: 3, anchorDate: monday, times: [morning]),
        rule,
      );
      expect(
        EveryNDaysRule(intervalDays: 3, anchorDate: tuesday, times: [morning]),
        isNot(rule),
      );
    });

    test('temporal, PRN, free-form and short-month cases stay explicit', () {
      expect(
        policy.evaluate(rule: EveryNHoursRule(6), localDate: monday).reason,
        ScheduleDateEligibilityReason.requiresInstantEvaluation,
      );
      expect(
        policy.evaluate(rule: const AsNeededRule(), localDate: monday).reason,
        ScheduleDateEligibilityReason.asNeeded,
      );
      expect(
        policy
            .evaluate(rule: FreeFormRule('orientação'), localDate: monday)
            .reason,
        ScheduleDateEligibilityReason.unstructured,
      );
      expect(
        policy
            .evaluate(
              rule: MonthlyRule(dayOfMonth: 31, times: [morning]),
              localDate: LocalDate(year: 2026, month: 2, day: 28),
            )
            .reason,
        ScheduleDateEligibilityReason.notEligible,
      );
    });

    test('monthly skips short months without shifting the configured day', () {
      final rule = MonthlyRule(dayOfMonth: 31, times: [morning]);
      final april30 = policy.evaluate(
        rule: rule,
        localDate: LocalDate(year: 2026, month: 4, day: 30),
      );
      final may1 = policy.evaluate(
        rule: rule,
        localDate: LocalDate(year: 2026, month: 5, day: 1),
      );
      final may30 = policy.evaluate(
        rule: rule,
        localDate: LocalDate(year: 2026, month: 5, day: 30),
      );
      final may31 = policy.evaluate(
        rule: rule,
        localDate: LocalDate(year: 2026, month: 5, day: 31),
      );

      expect(april30.reason, ScheduleDateEligibilityReason.notEligible);
      expect(april30.expectationKind, ExpectationKind.none);
      expect(may1.reason, ScheduleDateEligibilityReason.notEligible);
      expect(may30.reason, ScheduleDateEligibilityReason.notEligible);
      expect(may31.reason, ScheduleDateEligibilityReason.eligible);
      expect(may31.expectationKind, ExpectationKind.recurringExpectation);
    });

    test(
      'weekly is one ISO weekday and single dose uses supplied local date',
      () {
        expect(
          policy
              .evaluate(
                rule: WeeklyRule(weekday: DateTime.monday, times: [morning]),
                localDate: monday,
              )
              .isEligible,
          isTrue,
        );
        final single = SingleDoseRule(DateTime(2026, 7, 20, 14, 30));
        expect(
          policy.evaluate(rule: single, localDate: monday).isEligible,
          isTrue,
        );
        expect(
          policy.evaluate(rule: single, localDate: tuesday).isEligible,
          isFalse,
        );
      },
    );

    test(
      'resolver returns canonical immutable times only on eligible dates',
      () {
        final plan = _plan();
        final daily = _schedule(
          plan: plan,
          rule: DailyAtTimesRule([night, morning, night]),
        );
        final resolved = resolver.resolve(schedule: daily, localDate: monday);
        expect(resolved.times, [morning, night]);
        expect(() => resolved.times.add(morning), throwsUnsupportedError);

        final weekdays = _schedule(
          plan: plan,
          rule: SpecificWeekdaysAtTimesRule(
            weekdays: WeekdaySet([DateTime.monday]),
            times: [morning],
          ),
        );
        expect(
          resolver.resolve(schedule: weekdays, localDate: tuesday).times,
          isEmpty,
        );
      },
    );

    test(
      'resolver distinguishes single, PRN, free-form and every-hours emptiness',
      () {
        final scheduled = _plan();
        final single = _schedule(
          plan: scheduled,
          rule: SingleDoseRule(DateTime(2026, 7, 20, 14, 30)),
        );
        expect(resolver.resolve(schedule: single, localDate: monday).times, [
          TimeOfDayValue(hour: 14, minute: 30),
        ]);
        final prnPlan = _plan(mode: RoutinePlanMode.asNeeded);
        expect(
          resolver
              .resolve(
                schedule: _schedule(plan: prnPlan, rule: const AsNeededRule()),
                localDate: monday,
              )
              .reason,
          ScheduleTimesResolutionReason.asNeeded,
        );
        expect(
          resolver
              .resolve(
                schedule: _schedule(
                  plan: scheduled,
                  rule: FreeFormRule('texto'),
                ),
                localDate: monday,
              )
              .reason,
          ScheduleTimesResolutionReason.unstructured,
        );
        expect(
          resolver
              .resolve(
                schedule: _schedule(plan: scheduled, rule: EveryNHoursRule(8)),
                localDate: monday,
              )
              .reason,
          ScheduleTimesResolutionReason.requiresInstantEvaluation,
        );
      },
    );
  });

  group('routine eligibility and schedule association', () {
    test('routine statuses and tombstone have explicit reasons', () {
      final plan = _plan(activatedAt: start);
      final schedule = _schedule(plan: plan, rule: _dailyRule());
      RoutineEligibilityResult evaluate(
        RoutineStatus status, {
        bool deleted = false,
      }) => const RoutineEligibilityPolicy().evaluate(
        routine: _routine(status: status, deletedAt: deleted ? start : null),
        plan: plan,
        schedule: schedule,
        pauses: const [],
        at: start,
        localDate: LocalDate.fromDateTime(start),
      );

      expect(evaluate(RoutineStatus.active).isEligible, isTrue);
      expect(
        evaluate(RoutineStatus.paused).reason,
        RoutineEligibilityReason.routinePaused,
      );
      expect(
        evaluate(RoutineStatus.completed).reason,
        RoutineEligibilityReason.routineCompleted,
      );
      expect(
        evaluate(RoutineStatus.canceled).reason,
        RoutineEligibilityReason.routineCanceled,
      );
      expect(
        evaluate(RoutineStatus.archived).reason,
        RoutineEligibilityReason.routineArchived,
      );
      expect(
        evaluate(RoutineStatus.active, deleted: true).reason,
        RoutineEligibilityReason.routineDeleted,
      );
    });

    test('disabled, paused, incompatible, PRN and free-form are explicit', () {
      final plan = _plan(activatedAt: start);
      RoutineEligibilityResult evaluate(
        RoutineSchedule schedule, {
        Iterable<RoutinePause> pauses = const [],
        RoutinePlan? evaluatedPlan,
      }) => const RoutineEligibilityPolicy().evaluate(
        routine: _routine(),
        plan: evaluatedPlan ?? plan,
        schedule: schedule,
        pauses: pauses,
        at: start,
        localDate: LocalDate.fromDateTime(start),
      );

      expect(
        evaluate(
          _schedule(plan: plan, rule: _dailyRule(), enabled: false),
        ).reason,
        RoutineEligibilityReason.scheduleDisabled,
      );
      expect(
        evaluate(
          _schedule(plan: plan, rule: _dailyRule()),
          pauses: [_pause(startsAt: start)],
        ).reason,
        RoutineEligibilityReason.paused,
      );
      expect(
        evaluate(
          _schedule(
            plan: _plan(id: _plan2),
            rule: _dailyRule(),
          ),
        ).reason,
        RoutineEligibilityReason.scheduleIncompatible,
      );
      final prn = _plan(mode: RoutinePlanMode.asNeeded, activatedAt: start);
      expect(
        evaluate(
          _schedule(plan: prn, rule: const AsNeededRule()),
          evaluatedPlan: prn,
        ).reason,
        RoutineEligibilityReason.asNeeded,
      );
      expect(
        evaluate(_schedule(plan: plan, rule: FreeFormRule('texto'))).reason,
        RoutineEligibilityReason.unsupportedRule,
      );
    });

    test(
      'association selects only current plan, reports orphans and is ordered',
      () {
        const selector = PlanScheduleSelector();
        final current = _plan(activatedAt: start);
        final old = _plan(id: _plan2, activatedAt: start);
        final first = _schedule(
          plan: current,
          rule: _dailyRule(),
          id: _schedule2,
          order: 1,
        );
        final second = _schedule(
          plan: current,
          rule: _dailyRule(),
          id: _schedule1,
          order: 0,
        );
        final disabled = _schedule(
          plan: current,
          rule: _dailyRule(),
          id: _schedule3,
          order: 2,
          enabled: false,
        );
        final historical = _schedule(
          plan: old,
          rule: _dailyRule(),
          id: _schedule4,
        );
        final orphanPlan = _plan(id: _missingPlan);
        final orphan = _schedule(
          plan: orphanPlan,
          rule: _dailyRule(),
          id: _schedule5,
        );

        final result = selector.select(
          selectedPlan: current,
          knownPlans: [current, old],
          schedules: [orphan, first, historical, disabled, second],
        );
        expect(result.schedules, [second, first]);
        expect(result.orphanSchedules, [orphan]);
        expect(result.reason, PlanScheduleSelectionReason.selectedWithOrphans);
        expect(
          selector
              .select(
                selectedPlan: current,
                knownPlans: [old, current],
                schedules: [second, first],
                includeDisabled: true,
              )
              .schedules,
          [second, first],
        );
        expect(() => result.schedules.add(first), throwsUnsupportedError);
      },
    );

    test(
      'structured result equality and input immutability are deterministic',
      () {
        final plan = _plan(activatedAt: start);
        final input = [_schedule(plan: plan, rule: _dailyRule())];
        final first = const PlanScheduleSelector().select(
          selectedPlan: plan,
          knownPlans: [plan],
          schedules: input,
        );
        final second = const PlanScheduleSelector().select(
          selectedPlan: plan,
          knownPlans: [plan],
          schedules: input.reversed,
        );
        expect(first, second);
        expect(first.hashCode, second.hashCode);
        expect(input.length, 1);
      },
    );
  });

  test('services use no global clock or infrastructure imports', () {
    final files = Directory('lib/features/smart_routines/domain/services')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    const forbidden = [
      'DateTime.now(',
      'package:flutter/',
      'drift',
      'supabase',
      'riverpod',
      'local_notifications',
    ];
    for (final file in files) {
      final source = file.readAsStringSync();
      for (final token in forbidden) {
        expect(source, isNot(contains(token)), reason: '${file.path}: $token');
      }
    }
  });
}

PauseEvaluationResult _pauseEvaluation(
  PauseEligibilityPolicy policy,
  Iterable<RoutinePause> pauses,
  DateTime at,
) => policy.evaluate(
  routineId: RoutineId(_routine1),
  planId: RoutinePlanId(_plan1),
  pauses: pauses,
  at: at,
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
  String routineId = _routine1,
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
  routineId: RoutineId(routineId),
  revision: revision,
  mode: mode,
  durationType: durationType,
  effectiveFrom: effectiveFrom ?? LocalDate(year: 2026, month: 7, day: 20),
  effectiveUntil: effectiveUntil,
  createdAt: DateTime.utc(2026, 7, 1),
  activatedAt: activatedAt,
  replacedAt: replacedAt,
  previousPlanId: previousPlanId,
);

RoutineSchedule _schedule({
  required RoutinePlan plan,
  required ScheduleRule rule,
  String id = _schedule1,
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

DailyAtTimesRule _dailyRule() =>
    DailyAtTimesRule([TimeOfDayValue(hour: 8, minute: 0)]);

RoutinePause _pause({
  String id = _pause1,
  String routineId = _routine1,
  RoutinePauseScope scope = RoutinePauseScope.routine,
  String? planId,
  required DateTime startsAt,
  DateTime? endsAt,
}) => RoutinePause(
  pauseId: RoutinePauseId(id),
  routineId: RoutineId(routineId),
  scope: scope,
  planId: planId == null ? null : RoutinePlanId(planId),
  startsAt: startsAt,
  endsAt: endsAt,
  createdAt: startsAt,
);

const _routine1 = '10000000-0000-4000-8000-000000000001';
const _routine2 = '10000000-0000-4000-8000-000000000002';
const _plan1 = '20000000-0000-4000-8000-000000000001';
const _plan2 = '20000000-0000-4000-8000-000000000002';
const _missingPlan = '20000000-0000-4000-8000-000000000099';
const _schedule1 = '30000000-0000-4000-8000-000000000001';
const _schedule2 = '30000000-0000-4000-8000-000000000002';
const _schedule3 = '30000000-0000-4000-8000-000000000003';
const _schedule4 = '30000000-0000-4000-8000-000000000004';
const _schedule5 = '30000000-0000-4000-8000-000000000005';
const _pause1 = '40000000-0000-4000-8000-000000000001';
const _pause2 = '40000000-0000-4000-8000-000000000002';
const _pause3 = '40000000-0000-4000-8000-000000000003';
const _pause4 = '40000000-0000-4000-8000-000000000004';
