import '../../../../core/domain/entity.dart';
import '../enums/routine_enums.dart';
import '../errors/smart_routine_validation_exception.dart';
import '../value_objects/typed_ids.dart';

final class RoutinePause extends Entity {
  factory RoutinePause({
    required RoutinePauseId pauseId,
    required RoutineId routineId,
    required RoutinePauseScope scope,
    required DateTime startsAt,
    required DateTime createdAt,
    RoutinePlanId? planId,
    DateTime? endsAt,
    String? reason,
  }) {
    if (endsAt != null && endsAt.isBefore(startsAt)) {
      throw const SmartRoutineValidationException(
        'invalid_pause_period',
        'Pause end cannot precede its start.',
      );
    }
    if (scope == RoutinePauseScope.plan && planId == null) {
      throw const SmartRoutineValidationException(
        'pause_plan_required',
        'Plan-scoped pause requires planId.',
      );
    }
    if (scope == RoutinePauseScope.routine && planId != null) {
      throw const SmartRoutineValidationException(
        'unexpected_pause_plan',
        'Routine-scoped pause cannot target a plan.',
      );
    }
    return RoutinePause._(
      pauseId: pauseId,
      routineId: routineId,
      planId: planId,
      scope: scope,
      startsAt: startsAt,
      endsAt: endsAt,
      reason: _optional(reason),
      createdAt: createdAt,
    );
  }

  const RoutinePause._({
    required this.pauseId,
    required this.routineId,
    required this.scope,
    required this.startsAt,
    required this.createdAt,
    this.planId,
    this.endsAt,
    this.reason,
  });

  final RoutinePauseId pauseId;
  @override
  String get id => pauseId.value;
  final RoutineId routineId;
  final RoutinePlanId? planId;
  final RoutinePauseScope scope;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String? reason;
  final DateTime createdAt;

  bool get isOpen => endsAt == null;

  RoutinePause close(DateTime at) {
    if (!isOpen) {
      throw const SmartRoutineValidationException(
        'pause_already_closed',
        'Closed pause cannot be closed again.',
      );
    }
    return RoutinePause(
      pauseId: pauseId,
      routineId: routineId,
      planId: planId,
      scope: scope,
      startsAt: startsAt,
      endsAt: at,
      reason: reason,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutinePause &&
          pauseId == other.pauseId &&
          routineId == other.routineId &&
          planId == other.planId &&
          scope == other.scope &&
          startsAt == other.startsAt &&
          endsAt == other.endsAt &&
          reason == other.reason &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
    pauseId,
    routineId,
    planId,
    scope,
    startsAt,
    endsAt,
    reason,
    createdAt,
  );
}

String? _optional(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
