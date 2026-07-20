import '../errors/smart_routine_validation_exception.dart';
import '../value_objects/routine_values.dart';

final class OccurrenceWindowResolver {
  const OccurrenceWindowResolver();

  OccurrenceWindow resolve({
    required DateTime targetAtUtc,
    required OccurrenceWindowDefinition definition,
    DateTime? nextTargetAtUtc,
  }) {
    if (!targetAtUtc.isUtc ||
        (nextTargetAtUtc != null && !nextTargetAtUtc.isUtc)) {
      throw const SmartRoutineValidationException(
        'occurrence_window_target_requires_utc',
        'Window targets must be UTC.',
      );
    }
    final naturalEnd = targetAtUtc.add(definition.lateTolerance);
    final end = nextTargetAtUtc != null && nextTargetAtUtc.isBefore(naturalEnd)
        ? nextTargetAtUtc
        : naturalEnd;
    final naturalOnTimeEnd = targetAtUtc.add(definition.onTimeTolerance);
    return OccurrenceWindow(
      windowStartsAt: targetAtUtc.subtract(definition.earlyTolerance),
      scheduledFor: targetAtUtc,
      onTimeEndsAt: naturalOnTimeEnd.isAfter(end) ? end : naturalOnTimeEnd,
      windowEndsAt: end,
    );
  }
}
