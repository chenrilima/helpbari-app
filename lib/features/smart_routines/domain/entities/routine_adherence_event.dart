import '../../../../core/domain/entity.dart';
import '../enums/routine_enums.dart';
import '../errors/smart_routine_validation_exception.dart';
import '../value_objects/routine_values.dart';
import '../value_objects/typed_ids.dart';

final class RoutineAdherenceEvent extends Entity {
  factory RoutineAdherenceEvent({
    required RoutineAdherenceEventId eventId,
    required RoutineOccurrenceId occurrenceId,
    required AdherenceEventType type,
    required DateTime occurredAt,
    required DateTime recordedAt,
    required DateTime createdAt,
    required AdherenceEventActor actor,
    RoutineAdherenceEventId? correctedEventId,
    String? reason,
    DoseValue? actualDose,
  }) {
    if (recordedAt.isBefore(createdAt)) {
      throw const SmartRoutineValidationException(
        'invalid_event_timestamps',
        'Event recordedAt cannot precede createdAt.',
      );
    }
    if (type == AdherenceEventType.correction && correctedEventId == null) {
      throw const SmartRoutineValidationException(
        'corrected_event_required',
        'Correction event requires correctedEventId.',
      );
    }
    if (type != AdherenceEventType.correction && correctedEventId != null) {
      throw const SmartRoutineValidationException(
        'unexpected_corrected_event',
        'Only correction events can reference a corrected event.',
      );
    }
    return RoutineAdherenceEvent._(
      eventId: eventId,
      occurrenceId: occurrenceId,
      type: type,
      occurredAt: occurredAt,
      recordedAt: recordedAt,
      createdAt: createdAt,
      actor: actor,
      correctedEventId: correctedEventId,
      reason: _optional(reason),
      actualDose: actualDose,
    );
  }

  const RoutineAdherenceEvent._({
    required this.eventId,
    required this.occurrenceId,
    required this.type,
    required this.occurredAt,
    required this.recordedAt,
    required this.createdAt,
    required this.actor,
    this.correctedEventId,
    this.reason,
    this.actualDose,
  });

  final RoutineAdherenceEventId eventId;
  @override
  String get id => eventId.value;
  final RoutineOccurrenceId occurrenceId;
  final AdherenceEventType type;
  final DateTime occurredAt;
  final DateTime recordedAt;
  final DateTime createdAt;
  final AdherenceEventActor actor;
  final RoutineAdherenceEventId? correctedEventId;
  final String? reason;
  final DoseValue? actualDose;

  RoutineAdherenceEvent createCorrection({
    required RoutineAdherenceEventId correctionId,
    required DateTime occurredAt,
    required DateTime recordedAt,
    required DateTime createdAt,
    required AdherenceEventActor actor,
    String? reason,
    DoseValue? actualDose,
  }) => RoutineAdherenceEvent(
    eventId: correctionId,
    occurrenceId: occurrenceId,
    type: AdherenceEventType.correction,
    occurredAt: occurredAt,
    recordedAt: recordedAt,
    createdAt: createdAt,
    actor: actor,
    correctedEventId: eventId,
    reason: reason,
    actualDose: actualDose,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutineAdherenceEvent &&
          eventId == other.eventId &&
          occurrenceId == other.occurrenceId &&
          type == other.type &&
          occurredAt == other.occurredAt &&
          recordedAt == other.recordedAt &&
          createdAt == other.createdAt &&
          actor == other.actor &&
          correctedEventId == other.correctedEventId &&
          reason == other.reason &&
          actualDose == other.actualDose;

  @override
  int get hashCode => Object.hash(
    eventId,
    occurrenceId,
    type,
    occurredAt,
    recordedAt,
    createdAt,
    actor,
    correctedEventId,
    reason,
    actualDose,
  );
}

String? _optional(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
