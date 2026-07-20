import '../entities/entities.dart';
import '../enums/routine_enums.dart';
import '../value_objects/local_date.dart';
import 'eligibility_results.dart';
import 'pause_eligibility_policy.dart';
import 'plan_validity_policy.dart';
import 'schedule_date_eligibility_policy.dart';
import 'schedule_plan_compatibility_policy.dart';

final class RoutineEligibilityPolicy {
  const RoutineEligibilityPolicy({
    this.planValidityPolicy = const PlanValidityPolicy(),
    this.compatibilityPolicy = const SchedulePlanCompatibilityPolicy(),
    this.pausePolicy = const PauseEligibilityPolicy(),
    this.datePolicy = const ScheduleDateEligibilityPolicy(),
  });

  final PlanValidityPolicy planValidityPolicy;
  final SchedulePlanCompatibilityPolicy compatibilityPolicy;
  final PauseEligibilityPolicy pausePolicy;
  final ScheduleDateEligibilityPolicy datePolicy;

  RoutineEligibilityResult evaluate({
    required SmartRoutine routine,
    required RoutinePlan plan,
    required RoutineSchedule schedule,
    required Iterable<RoutinePause> pauses,
    required DateTime at,
    required LocalDate localDate,
    LocalDate? anchorDate,
  }) {
    if (routine.isDeleted) {
      return const RoutineEligibilityResult(
        RoutineEligibilityReason.routineDeleted,
      );
    }
    final statusReason = switch (routine.status) {
      RoutineStatus.active => null,
      RoutineStatus.paused => RoutineEligibilityReason.routinePaused,
      RoutineStatus.completed => RoutineEligibilityReason.routineCompleted,
      RoutineStatus.canceled => RoutineEligibilityReason.routineCanceled,
      RoutineStatus.archived => RoutineEligibilityReason.routineArchived,
    };
    if (statusReason != null) return RoutineEligibilityResult(statusReason);
    if (plan.routineId != routine.routineId) {
      return const RoutineEligibilityResult(
        RoutineEligibilityReason.routineInactive,
      );
    }
    final validity = planValidityPolicy.evaluate(plan, at);
    if (!validity.isValid) {
      return RoutineEligibilityResult(switch (validity.reason) {
        PlanValidityReason.notActivated =>
          RoutineEligibilityReason.planNotActivated,
        PlanValidityReason.planNotStarted =>
          RoutineEligibilityReason.planNotStarted,
        PlanValidityReason.planExpired => RoutineEligibilityReason.planExpired,
        PlanValidityReason.planReplaced =>
          RoutineEligibilityReason.planReplaced,
        PlanValidityReason.valid => RoutineEligibilityReason.eligible,
      });
    }
    if (!compatibilityPolicy
        .evaluate(plan: plan, schedule: schedule)
        .isCompatible) {
      return const RoutineEligibilityResult(
        RoutineEligibilityReason.scheduleIncompatible,
      );
    }
    if (!schedule.isEnabled) {
      return const RoutineEligibilityResult(
        RoutineEligibilityReason.scheduleDisabled,
      );
    }
    final pause = pausePolicy.evaluate(
      routineId: routine.routineId,
      planId: plan.planId,
      pauses: pauses,
      at: at,
    );
    if (pause.isPaused) {
      return const RoutineEligibilityResult(RoutineEligibilityReason.paused);
    }
    final date = datePolicy.evaluate(
      rule: schedule.rule,
      localDate: localDate,
      anchorDate: anchorDate,
    );
    return RoutineEligibilityResult(switch (date.reason) {
      ScheduleDateEligibilityReason.eligible =>
        RoutineEligibilityReason.eligible,
      ScheduleDateEligibilityReason.asNeeded =>
        RoutineEligibilityReason.asNeeded,
      ScheduleDateEligibilityReason.notEligible =>
        RoutineEligibilityReason.dateNotEligible,
      ScheduleDateEligibilityReason.unstructured ||
      ScheduleDateEligibilityReason.unsupported ||
      ScheduleDateEligibilityReason.anchorRequired ||
      ScheduleDateEligibilityReason.requiresInstantEvaluation =>
        RoutineEligibilityReason.unsupportedRule,
    });
  }
}
