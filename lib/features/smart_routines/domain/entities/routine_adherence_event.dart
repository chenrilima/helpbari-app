import '../../../../core/domain/entity.dart';
import '../enums/routine_enums.dart';
import '../errors/smart_routine_validation_exception.dart';
import '../value_objects/routine_values.dart';
import '../value_objects/typed_ids.dart';

/// Immutable append-only fact. Corrections are new events and never mutate the
/// referenced event.
final class RoutineAdherenceEvent extends Entity {
  factory RoutineAdherenceEvent({
    required RoutineAdherenceEventId eventId,
    required RoutineOccurrenceId occurrenceId,
    required RoutineId routineId,
    required RoutinePlanId planId,
    required AdherenceEventType type,
    required DateTime occurredAtUtc,
    required DateTime recordedAtUtc,
    required AdherenceEventActor actor,
    RoutineScheduleId? scheduleId,
    RoutineAdherenceEventId? referencedEventId,
    AdherenceCorrectionAction? correctionAction,
    AdherenceEventType? replacementType,
    DateTime? replacementOccurredAtUtc,
    OccurrenceWindow? rescheduledWindow,
    String? note,
    DoseValue? actualDose,
  }) {
    _requireUtc(occurredAtUtc, 'occurredAtUtc');
    _requireUtc(recordedAtUtc, 'recordedAtUtc');
    if (replacementOccurredAtUtc != null) {
      _requireUtc(replacementOccurredAtUtc, 'replacementOccurredAtUtc');
    }
    final isCorrection = type == AdherenceEventType.correction;
    if (isCorrection != (referencedEventId != null)) {
      throw const SmartRoutineValidationException(
        'invalid_correction_reference',
        'Correction events require one referenced event and other events cannot reference one.',
      );
    }
    if (isCorrection != (correctionAction != null)) {
      throw const SmartRoutineValidationException(
        'invalid_correction_action',
        'Correction events require an explicit correction action.',
      );
    }
    if (referencedEventId == eventId) {
      throw const SmartRoutineValidationException(
        'self_referencing_correction',
        'An event cannot correct itself.',
      );
    }
    if (correctionAction == AdherenceCorrectionAction.replace &&
        replacementType == null) {
      throw const SmartRoutineValidationException(
        'correction_replacement_required',
        'Replacement correction requires a replacement type.',
      );
    }
    if (correctionAction != AdherenceCorrectionAction.replace &&
        (replacementType != null || replacementOccurredAtUtc != null)) {
      throw const SmartRoutineValidationException(
        'unexpected_correction_replacement',
        'Only replacement corrections may carry replacement values.',
      );
    }
    if (replacementType == AdherenceEventType.correction) {
      throw const SmartRoutineValidationException(
        'nested_correction_type',
        'A correction cannot replace an event with another correction type.',
      );
    }
    final effectiveType = replacementType ?? type;
    if ((effectiveType == AdherenceEventType.rescheduled) !=
        (rescheduledWindow != null)) {
      throw const SmartRoutineValidationException(
        'invalid_reschedule_window',
        'A rescheduled event requires exactly one replacement window.',
      );
    }
    return RoutineAdherenceEvent._(
      eventId: eventId,
      occurrenceId: occurrenceId,
      routineId: routineId,
      planId: planId,
      scheduleId: scheduleId,
      type: type,
      occurredAtUtc: occurredAtUtc,
      recordedAtUtc: recordedAtUtc,
      actor: actor,
      referencedEventId: referencedEventId,
      correctionAction: correctionAction,
      replacementType: replacementType,
      replacementOccurredAtUtc: replacementOccurredAtUtc,
      rescheduledWindow: rescheduledWindow,
      note: _optional(note),
      actualDose: actualDose,
    );
  }

  const RoutineAdherenceEvent._({
    required this.eventId,
    required this.occurrenceId,
    required this.routineId,
    required this.planId,
    required this.type,
    required this.occurredAtUtc,
    required this.recordedAtUtc,
    required this.actor,
    this.scheduleId,
    this.referencedEventId,
    this.correctionAction,
    this.replacementType,
    this.replacementOccurredAtUtc,
    this.rescheduledWindow,
    this.note,
    this.actualDose,
  });

  final RoutineAdherenceEventId eventId;
  @override
  String get id => eventId.value;
  final RoutineOccurrenceId occurrenceId;
  final RoutineId routineId;
  final RoutinePlanId planId;
  final RoutineScheduleId? scheduleId;
  final AdherenceEventType type;
  final DateTime occurredAtUtc;
  final DateTime recordedAtUtc;
  final AdherenceEventActor actor;
  final RoutineAdherenceEventId? referencedEventId;
  final AdherenceCorrectionAction? correctionAction;
  final AdherenceEventType? replacementType;
  final DateTime? replacementOccurredAtUtc;
  final OccurrenceWindow? rescheduledWindow;
  final String? note;
  final DoseValue? actualDose;

  DateTime get effectiveAtUtc => replacementOccurredAtUtc ?? occurredAtUtc;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutineAdherenceEvent &&
          eventId == other.eventId &&
          occurrenceId == other.occurrenceId &&
          routineId == other.routineId &&
          planId == other.planId &&
          scheduleId == other.scheduleId &&
          type == other.type &&
          occurredAtUtc == other.occurredAtUtc &&
          recordedAtUtc == other.recordedAtUtc &&
          actor == other.actor &&
          referencedEventId == other.referencedEventId &&
          correctionAction == other.correctionAction &&
          replacementType == other.replacementType &&
          replacementOccurredAtUtc == other.replacementOccurredAtUtc &&
          rescheduledWindow == other.rescheduledWindow &&
          note == other.note &&
          actualDose == other.actualDose;

  @override
  int get hashCode => Object.hashAll([
    eventId,
    occurrenceId,
    routineId,
    planId,
    scheduleId,
    type,
    occurredAtUtc,
    recordedAtUtc,
    actor,
    referencedEventId,
    correctionAction,
    replacementType,
    replacementOccurredAtUtc,
    rescheduledWindow,
    note,
    actualDose,
  ]);
}

void _requireUtc(DateTime value, String field) {
  if (!value.isUtc) {
    throw SmartRoutineValidationException(
      'adherence_event_requires_utc',
      '$field must be UTC.',
    );
  }
}

String? _optional(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
