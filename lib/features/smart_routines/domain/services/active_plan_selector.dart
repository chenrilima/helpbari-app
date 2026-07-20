import '../entities/routine_plan.dart';
import '../value_objects/typed_ids.dart';
import 'eligibility_results.dart';
import 'plan_validity_policy.dart';

final class ActivePlanSelector {
  const ActivePlanSelector({this.validityPolicy = const PlanValidityPolicy()});
  final PlanValidityPolicy validityPolicy;

  PlanSelectionResult select({
    required RoutineId routineId,
    required Iterable<RoutinePlan> plans,
    required DateTime at,
  }) {
    final ordered = plans.toList()
      ..sort((left, right) {
        final revision = left.revision.compareTo(right.revision);
        return revision != 0
            ? revision
            : left.planId.value.compareTo(right.planId.value);
      });
    if (ordered.any((plan) => plan.routineId != routineId)) {
      return PlanSelectionResult(reason: PlanSelectionReason.foreignRoutine);
    }
    final revisions = <int>{};
    for (final plan in ordered) {
      if (!revisions.add(plan.revision)) {
        return PlanSelectionResult(
          reason: PlanSelectionReason.duplicateRevision,
          conflictingPlans: ordered.where(
            (candidate) => candidate.revision == plan.revision,
          ),
        );
      }
    }
    if (!_hasConsistentChain(ordered)) {
      return PlanSelectionResult(reason: PlanSelectionReason.inconsistentChain);
    }
    final valid = ordered
        .where((plan) => validityPolicy.evaluate(plan, at).isValid)
        .toList();
    if (valid.isEmpty) {
      return PlanSelectionResult(reason: PlanSelectionReason.noValidPlan);
    }
    if (valid.length > 1) {
      return PlanSelectionResult(
        reason: PlanSelectionReason.multipleValidPlans,
        conflictingPlans: valid,
      );
    }
    return PlanSelectionResult(
      reason: PlanSelectionReason.selected,
      selectedPlan: valid.single,
    );
  }

  bool _hasConsistentChain(List<RoutinePlan> plans) {
    if (plans.isEmpty) return true;
    final byId = {for (final plan in plans) plan.planId: plan};
    for (final plan in plans) {
      if (plan.revision == 1) {
        if (plan.previousPlanId != null) return false;
        continue;
      }
      final previous = plan.previousPlanId == null
          ? null
          : byId[plan.previousPlanId];
      if (previous == null || previous.revision != plan.revision - 1) {
        return false;
      }
    }
    return true;
  }
}
