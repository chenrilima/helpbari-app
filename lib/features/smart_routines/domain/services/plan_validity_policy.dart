import '../entities/routine_plan.dart';
import '../value_objects/local_date.dart';
import 'eligibility_results.dart';

/// Clinical dates are inclusive. Operational instants use
/// [activatedAt, replacedAt), with an exclusive replacement boundary.
final class PlanValidityPolicy {
  const PlanValidityPolicy();

  PlanValidityResult evaluate({
    required RoutinePlan plan,
    required DateTime at,
    required LocalDate clinicalDate,
  }) {
    if (plan.activatedAt == null) {
      return const PlanValidityResult(PlanValidityReason.notActivated);
    }
    if (clinicalDate.compareTo(plan.effectiveFrom) < 0 ||
        at.isBefore(plan.activatedAt!)) {
      return const PlanValidityResult(PlanValidityReason.planNotStarted);
    }
    if (plan.replacedAt != null && !at.isBefore(plan.replacedAt!)) {
      return const PlanValidityResult(PlanValidityReason.planReplaced);
    }
    if (plan.effectiveUntil != null &&
        clinicalDate.compareTo(plan.effectiveUntil!) > 0) {
      return const PlanValidityResult(PlanValidityReason.planExpired);
    }
    return const PlanValidityResult(PlanValidityReason.valid);
  }
}
