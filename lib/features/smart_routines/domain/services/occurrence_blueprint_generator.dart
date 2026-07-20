import '../entities/entities.dart';
import '../value_objects/local_date.dart';
import '../value_objects/occurrence_blueprint.dart';
import '../value_objects/schedule_rule.dart';
import '../value_objects/typed_ids.dart';
import 'active_plan_selector.dart';
import 'eligibility_results.dart';
import 'occurrence_blueprint_generation_result.dart';
import 'pause_eligibility_policy.dart';
import 'plan_schedule_selector.dart';
import 'routine_eligibility_policy.dart';
import 'schedule_times_resolver.dart';

final class OccurrenceBlueprintGenerator {
  const OccurrenceBlueprintGenerator({
    this.planSelector = const ActivePlanSelector(),
    this.scheduleSelector = const PlanScheduleSelector(),
    this.eligibilityPolicy = const RoutineEligibilityPolicy(),
    this.pausePolicy = const PauseEligibilityPolicy(),
    this.timesResolver = const ScheduleTimesResolver(),
  });

  final ActivePlanSelector planSelector;
  final PlanScheduleSelector scheduleSelector;
  final RoutineEligibilityPolicy eligibilityPolicy;
  final PauseEligibilityPolicy pausePolicy;
  final ScheduleTimesResolver timesResolver;

  OccurrenceBlueprintGenerationResult generate({
    required SmartRoutine routine,
    required Iterable<RoutinePlan> plans,
    required Iterable<RoutineSchedule> schedules,
    required Iterable<RoutinePause> pauses,
    required LocalDate clinicalDate,
    required DateTime operationalAt,
  }) {
    final planInput = plans.toList();
    final scheduleInput = schedules.toList();
    final pauseInput = pauses.toList();
    final selection = planSelector.select(
      routineId: routine.routineId,
      plans: planInput,
      at: operationalAt,
      clinicalDate: clinicalDate,
    );
    if (!selection.isSelected) {
      return _selectionFailure(selection);
    }
    final plan = selection.selectedPlan!;
    final scheduleSelection = scheduleSelector.select(
      selectedPlan: plan,
      knownPlans: planInput,
      schedules: scheduleInput,
      includeDisabled: true,
    );
    final issues = <OccurrenceBlueprintGenerationIssue>{
      if (scheduleSelection.orphanSchedules.isNotEmpty)
        OccurrenceBlueprintGenerationIssue.orphanSchedule,
    };
    final selectedSchedules = scheduleSelection.schedules;
    final ignoredIds = scheduleInput
        .where((schedule) => schedule.planId != plan.planId)
        .map((schedule) => schedule.scheduleId)
        .toSet();
    if (selectedSchedules.isEmpty) {
      return _result(
        status: OccurrenceBlueprintGenerationStatus.noSchedules,
        selectedPlan: plan,
        ignoredIds: ignoredIds,
        issues: issues,
      );
    }

    final blueprints = <OccurrenceBlueprint>[];
    final evaluatedIds = <RoutineScheduleId>[];
    final reasons = <RoutineEligibilityReason>[];
    var hasAsNeeded = false;
    var hasUnstructured = false;
    var hasInstantRule = false;
    var hasUnsupported = false;

    for (final schedule in selectedSchedules) {
      evaluatedIds.add(schedule.scheduleId);
      final pause = pausePolicy.evaluate(
        routineId: routine.routineId,
        planId: plan.planId,
        pauses: pauseInput,
        at: operationalAt,
      );
      if (pause.hasOverlap) {
        issues.add(OccurrenceBlueprintGenerationIssue.overlappingPauses);
      }
      final eligibility = eligibilityPolicy.evaluate(
        routine: routine,
        plan: plan,
        schedule: schedule,
        pauses: pauseInput,
        at: operationalAt,
        localDate: clinicalDate,
      );
      reasons.add(eligibility.reason);
      if (!eligibility.isEligible) {
        ignoredIds.add(schedule.scheduleId);
        if (eligibility.reason ==
            RoutineEligibilityReason.scheduleIncompatible) {
          issues.add(OccurrenceBlueprintGenerationIssue.incompatibleSchedule);
        }
        hasAsNeeded |= schedule.rule is AsNeededRule;
        hasUnstructured |= schedule.rule is FreeFormRule;
        hasInstantRule |= schedule.rule is EveryNHoursRule;
        hasUnsupported |=
            eligibility.reason == RoutineEligibilityReason.unsupportedRule &&
            schedule.rule is! FreeFormRule &&
            schedule.rule is! EveryNHoursRule;
        continue;
      }
      final resolution = timesResolver.resolve(
        schedule: schedule,
        localDate: clinicalDate,
      );
      final times = resolution.times.toSet().toList()..sort();
      for (var sequence = 0; sequence < times.length; sequence++) {
        final time = times[sequence];
        blueprints.add(
          OccurrenceBlueprint(
            routineId: routine.routineId,
            planId: plan.planId,
            scheduleId: schedule.scheduleId,
            clinicalDate: clinicalDate,
            localTime: time,
            timeZone: schedule.timeZone,
            expectationKind: resolution.expectationKind,
            sequence: sequence,
            originalLocalDate: clinicalDate,
            originalLocalTime: time,
            sourceRuleType: schedule.rule.frequencyType,
            scheduleDisplayOrder: schedule.displayOrder,
          ),
        );
      }
    }

    final normalized = _normalize(blueprints);
    if (normalized.isNotEmpty) {
      return _result(
        status: OccurrenceBlueprintGenerationStatus.generated,
        blueprints: normalized,
        selectedPlan: plan,
        evaluatedIds: evaluatedIds,
        ignoredIds: ignoredIds,
        issues: issues,
      );
    }
    final status = _emptyStatus(
      reasons: reasons,
      hasAsNeeded: hasAsNeeded,
      hasUnstructured: hasUnstructured,
      hasInstantRule: hasInstantRule,
      hasUnsupported: hasUnsupported,
      hasIssues: issues.contains(
        OccurrenceBlueprintGenerationIssue.incompatibleSchedule,
      ),
    );
    return _result(
      status: status,
      selectedPlan: plan,
      evaluatedIds: evaluatedIds,
      ignoredIds: ignoredIds,
      issues: issues,
    );
  }

  OccurrenceBlueprintGenerationResult _selectionFailure(
    PlanSelectionResult selection,
  ) {
    final issue = switch (selection.reason) {
      PlanSelectionReason.duplicateRevision =>
        OccurrenceBlueprintGenerationIssue.duplicateRevision,
      PlanSelectionReason.foreignRoutine =>
        OccurrenceBlueprintGenerationIssue.foreignRoutine,
      PlanSelectionReason.inconsistentChain =>
        OccurrenceBlueprintGenerationIssue.inconsistentPlanChain,
      _ => null,
    };
    final status = switch (selection.reason) {
      PlanSelectionReason.noValidPlan =>
        OccurrenceBlueprintGenerationStatus.noValidPlan,
      PlanSelectionReason.multipleValidPlans =>
        OccurrenceBlueprintGenerationStatus.multipleValidPlans,
      PlanSelectionReason.selected =>
        OccurrenceBlueprintGenerationStatus.generated,
      _ => OccurrenceBlueprintGenerationStatus.inconsistentData,
    };
    return _result(status: status, issues: [?issue]);
  }

  OccurrenceBlueprintGenerationStatus _emptyStatus({
    required List<RoutineEligibilityReason> reasons,
    required bool hasAsNeeded,
    required bool hasUnstructured,
    required bool hasInstantRule,
    required bool hasUnsupported,
    required bool hasIssues,
  }) {
    if (hasIssues) return OccurrenceBlueprintGenerationStatus.inconsistentData;
    if (reasons.isNotEmpty &&
        reasons.every((reason) => reason == RoutineEligibilityReason.paused)) {
      return OccurrenceBlueprintGenerationStatus.paused;
    }
    if (hasAsNeeded && !hasUnstructured && !hasInstantRule) {
      return OccurrenceBlueprintGenerationStatus.asNeededOnly;
    }
    if (hasUnstructured && !hasAsNeeded && !hasInstantRule) {
      return OccurrenceBlueprintGenerationStatus.unstructuredOnly;
    }
    if (hasInstantRule) {
      return OccurrenceBlueprintGenerationStatus.requiresInstantEvaluation;
    }
    if (hasUnsupported) {
      return OccurrenceBlueprintGenerationStatus.unsupportedRule;
    }
    const routineReasons = {
      RoutineEligibilityReason.routineInactive,
      RoutineEligibilityReason.routinePaused,
      RoutineEligibilityReason.routineCompleted,
      RoutineEligibilityReason.routineCanceled,
      RoutineEligibilityReason.routineArchived,
      RoutineEligibilityReason.routineDeleted,
      RoutineEligibilityReason.planNotStarted,
      RoutineEligibilityReason.planExpired,
      RoutineEligibilityReason.planNotActivated,
      RoutineEligibilityReason.planReplaced,
    };
    if (reasons.any(routineReasons.contains)) {
      return OccurrenceBlueprintGenerationStatus.routineIneligible;
    }
    return OccurrenceBlueprintGenerationStatus.noEligibleSchedules;
  }

  List<OccurrenceBlueprint> _normalize(
    Iterable<OccurrenceBlueprint> blueprints,
  ) {
    final byKey = <OccurrenceBlueprintLogicalKey, OccurrenceBlueprint>{};
    for (final blueprint in blueprints) {
      byKey.putIfAbsent(blueprint.logicalKey, () => blueprint);
    }
    return byKey.values.toList()..sort();
  }

  OccurrenceBlueprintGenerationResult _result({
    required OccurrenceBlueprintGenerationStatus status,
    Iterable<OccurrenceBlueprint> blueprints = const [],
    RoutinePlan? selectedPlan,
    Iterable<RoutineScheduleId> evaluatedIds = const [],
    Iterable<RoutineScheduleId> ignoredIds = const [],
    Iterable<OccurrenceBlueprintGenerationIssue> issues = const [],
  }) {
    final evaluated = evaluatedIds.toSet().toList()
      ..sort((left, right) => left.value.compareTo(right.value));
    final ignored = ignoredIds.toSet().toList()
      ..sort((left, right) => left.value.compareTo(right.value));
    final orderedIssues = issues.toSet().toList()
      ..sort((left, right) => left.index.compareTo(right.index));
    return OccurrenceBlueprintGenerationResult(
      status: status,
      blueprints: blueprints,
      selectedPlan: selectedPlan,
      evaluatedScheduleIds: evaluated,
      ignoredScheduleIds: ignored,
      issues: orderedIssues,
    );
  }
}
