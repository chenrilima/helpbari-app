import '../entities/routine_plan.dart';
import '../entities/routine_schedule.dart';
import 'eligibility_results.dart';

final class PlanScheduleSelector {
  const PlanScheduleSelector();

  PlanScheduleSelectionResult select({
    required RoutinePlan? selectedPlan,
    required Iterable<RoutinePlan> knownPlans,
    required Iterable<RoutineSchedule> schedules,
    bool includeDisabled = false,
  }) {
    final planIds = knownPlans.map((plan) => plan.planId).toSet();
    final allSchedules = schedules.toList();
    final orphans =
        allSchedules
            .where((schedule) => !planIds.contains(schedule.planId))
            .toList()
          ..sort(_compareSchedules);
    if (selectedPlan == null) {
      return PlanScheduleSelectionResult(
        reason: PlanScheduleSelectionReason.noSelectedPlan,
        schedules: const [],
        orphanSchedules: orphans,
      );
    }
    final selected =
        allSchedules
            .where(
              (schedule) =>
                  schedule.planId == selectedPlan.planId &&
                  (includeDisabled || schedule.isEnabled),
            )
            .toList()
          ..sort(_compareSchedules);
    return PlanScheduleSelectionResult(
      reason: orphans.isEmpty
          ? PlanScheduleSelectionReason.selected
          : PlanScheduleSelectionReason.selectedWithOrphans,
      schedules: selected,
      orphanSchedules: orphans,
    );
  }

  int _compareSchedules(RoutineSchedule left, RoutineSchedule right) {
    final order = left.displayOrder.compareTo(right.displayOrder);
    return order != 0
        ? order
        : left.scheduleId.value.compareTo(right.scheduleId.value);
  }
}
