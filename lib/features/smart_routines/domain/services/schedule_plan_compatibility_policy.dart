import '../entities/routine_plan.dart';
import '../entities/routine_schedule.dart';
import '../enums/routine_enums.dart';
import '../value_objects/schedule_rule.dart';
import 'eligibility_results.dart';

final class SchedulePlanCompatibilityPolicy {
  const SchedulePlanCompatibilityPolicy();

  ScheduleCompatibilityResult evaluate({
    required RoutinePlan plan,
    required RoutineSchedule schedule,
  }) {
    if (schedule.planId != plan.planId) {
      return const ScheduleCompatibilityResult(
        ScheduleCompatibilityReason.planIdMismatch,
      );
    }
    if (plan.mode == RoutinePlanMode.asNeeded &&
        schedule.rule is! AsNeededRule) {
      return const ScheduleCompatibilityResult(
        ScheduleCompatibilityReason.asNeededPlanWithScheduledRule,
      );
    }
    if (plan.mode == RoutinePlanMode.scheduled &&
        schedule.rule is AsNeededRule) {
      return const ScheduleCompatibilityResult(
        ScheduleCompatibilityReason.scheduledPlanWithAsNeededRule,
      );
    }
    return const ScheduleCompatibilityResult(
      ScheduleCompatibilityReason.compatible,
    );
  }
}
