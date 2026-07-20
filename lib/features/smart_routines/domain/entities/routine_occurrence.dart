import '../../../../core/domain/entity.dart';
import '../enums/routine_enums.dart';
import '../errors/smart_routine_validation_exception.dart';
import '../value_objects/routine_values.dart';
import '../value_objects/typed_ids.dart';

final class RoutineOccurrence extends Entity {
  factory RoutineOccurrence({
    required RoutineOccurrenceId occurrenceId,
    required RoutineId routineId,
    required RoutinePlanId planId,
    required RoutineOccurrenceOrigin origin,
    required OccurrenceWindow originalWindow,
    required OccurrenceWindow currentWindow,
    required RoutineOccurrenceStatus status,
    RoutineScheduleId? scheduleId,
  }) {
    final isAdHoc = origin == RoutineOccurrenceOrigin.adHocAsNeeded;
    if (isAdHoc && scheduleId != null) {
      throw const SmartRoutineValidationException(
        'unexpected_prn_schedule',
        'Ad hoc as-needed occurrence cannot target a recurring schedule.',
      );
    }
    if (!isAdHoc && scheduleId == null) {
      throw const SmartRoutineValidationException(
        'recurring_occurrence_schedule_required',
        'Recurring occurrence requires scheduleId.',
      );
    }
    if (status != RoutineOccurrenceStatus.rescheduled &&
        originalWindow != currentWindow) {
      throw const SmartRoutineValidationException(
        'unexpected_occurrence_window_change',
        'Only a rescheduled occurrence may change its current window.',
      );
    }
    return RoutineOccurrence._(
      occurrenceId: occurrenceId,
      routineId: routineId,
      planId: planId,
      scheduleId: scheduleId,
      origin: origin,
      originalWindow: originalWindow,
      currentWindow: currentWindow,
      status: status,
    );
  }

  const RoutineOccurrence._({
    required this.occurrenceId,
    required this.routineId,
    required this.planId,
    required this.origin,
    required this.originalWindow,
    required this.currentWindow,
    required this.status,
    this.scheduleId,
  });

  final RoutineOccurrenceId occurrenceId;
  @override
  String get id => occurrenceId.value;
  final RoutineId routineId;
  final RoutinePlanId planId;
  final RoutineScheduleId? scheduleId;
  final RoutineOccurrenceOrigin origin;
  final OccurrenceWindow originalWindow;
  final OccurrenceWindow currentWindow;
  final RoutineOccurrenceStatus status;

  DateTime get originalScheduledFor => originalWindow.scheduledFor;
  DateTime get currentScheduledFor => currentWindow.scheduledFor;

  RoutineOccurrence reschedule(OccurrenceWindow newWindow) {
    if ({
      RoutineOccurrenceStatus.canceled,
      RoutineOccurrenceStatus.paused,
      RoutineOccurrenceStatus.notApplicable,
    }.contains(status)) {
      throw const SmartRoutineValidationException(
        'occurrence_not_reschedulable',
        'Resolved non-applicable occurrence cannot be rescheduled.',
      );
    }
    return RoutineOccurrence(
      occurrenceId: occurrenceId,
      routineId: routineId,
      planId: planId,
      scheduleId: scheduleId,
      origin: origin,
      originalWindow: originalWindow,
      currentWindow: newWindow,
      status: RoutineOccurrenceStatus.rescheduled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutineOccurrence &&
          occurrenceId == other.occurrenceId &&
          routineId == other.routineId &&
          planId == other.planId &&
          scheduleId == other.scheduleId &&
          origin == other.origin &&
          originalWindow == other.originalWindow &&
          currentWindow == other.currentWindow &&
          status == other.status;

  @override
  int get hashCode => Object.hash(
    occurrenceId,
    routineId,
    planId,
    scheduleId,
    origin,
    originalWindow,
    currentWindow,
    status,
  );
}
