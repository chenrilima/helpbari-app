import '../entities/routine_plan.dart';
import 'eligibility_results.dart';

/// Evaluates plan instants with inclusive starts and effective end, while the
/// replacement boundary is exclusive: [activatedAt, replacedAt).
final class PlanValidityPolicy {
  const PlanValidityPolicy();

  PlanValidityResult evaluate(RoutinePlan plan, DateTime at) {
    if (plan.activatedAt == null) {
      return const PlanValidityResult(PlanValidityReason.notActivated);
    }
    if (at.isBefore(plan.effectiveFrom) || at.isBefore(plan.activatedAt!)) {
      return const PlanValidityResult(PlanValidityReason.planNotStarted);
    }
    if (plan.replacedAt != null && !at.isBefore(plan.replacedAt!)) {
      return const PlanValidityResult(PlanValidityReason.planReplaced);
    }
    if (plan.effectiveUntil != null && at.isAfter(plan.effectiveUntil!)) {
      return const PlanValidityResult(PlanValidityReason.planExpired);
    }
    return const PlanValidityResult(PlanValidityReason.valid);
  }
}
