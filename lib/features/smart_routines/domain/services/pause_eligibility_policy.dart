import '../entities/routine_pause.dart';
import '../enums/routine_enums.dart';
import '../value_objects/typed_ids.dart';
import 'eligibility_results.dart';

/// Pause intervals are start-inclusive and end-exclusive: [startsAt, endsAt).
final class PauseEligibilityPolicy {
  const PauseEligibilityPolicy();

  PauseEvaluationResult evaluate({
    required RoutineId routineId,
    required RoutinePlanId planId,
    required Iterable<RoutinePause> pauses,
    required DateTime at,
  }) {
    final applicable =
        pauses.where((pause) {
          if (pause.routineId != routineId) return false;
          if (pause.scope == RoutinePauseScope.plan && pause.planId != planId) {
            return false;
          }
          return !at.isBefore(pause.startsAt) &&
              (pause.endsAt == null || at.isBefore(pause.endsAt!));
        }).toList()..sort((left, right) {
          final start = left.startsAt.compareTo(right.startsAt);
          return start != 0
              ? start
              : left.pauseId.value.compareTo(right.pauseId.value);
        });
    return PauseEvaluationResult(
      applicablePauses: applicable,
      hasOverlap: applicable.length > 1,
    );
  }
}
