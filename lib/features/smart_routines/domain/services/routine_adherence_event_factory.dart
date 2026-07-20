import '../entities/entities.dart';
import '../enums/routine_enums.dart';
import '../errors/smart_routine_validation_exception.dart';
import '../value_objects/routine_values.dart';
import '../value_objects/typed_ids.dart';

final class RoutineAdherenceEventFactory {
  const RoutineAdherenceEventFactory();

  RoutineAdherenceEvent taken({
    required RoutineOccurrence occurrence,
    required RoutineAdherenceEventId eventId,
    required DateTime occurredAtUtc,
    required DateTime recordedAtUtc,
    required AdherenceEventActor actor,
    String? note,
    DoseValue? actualDose,
  }) => _event(
    occurrence: occurrence,
    eventId: eventId,
    type: AdherenceEventType.taken,
    occurredAtUtc: occurredAtUtc,
    recordedAtUtc: recordedAtUtc,
    actor: actor,
    note: note,
    actualDose: actualDose,
  );

  RoutineAdherenceEvent skipped({
    required RoutineOccurrence occurrence,
    required RoutineAdherenceEventId eventId,
    required DateTime occurredAtUtc,
    required DateTime recordedAtUtc,
    required AdherenceEventActor actor,
    String? note,
  }) => _event(
    occurrence: occurrence,
    eventId: eventId,
    type: AdherenceEventType.skipped,
    occurredAtUtc: occurredAtUtc,
    recordedAtUtc: recordedAtUtc,
    actor: actor,
    note: note,
  );

  RoutineAdherenceEvent canceled({
    required RoutineOccurrence occurrence,
    required RoutineAdherenceEventId eventId,
    required DateTime occurredAtUtc,
    required DateTime recordedAtUtc,
    required AdherenceEventActor actor,
    String? note,
  }) => _event(
    occurrence: occurrence,
    eventId: eventId,
    type: AdherenceEventType.canceled,
    occurredAtUtc: occurredAtUtc,
    recordedAtUtc: recordedAtUtc,
    actor: actor,
    note: note,
  );

  RoutineAdherenceEvent rescheduled({
    required RoutineOccurrence occurrence,
    required RoutineAdherenceEventId eventId,
    required DateTime occurredAtUtc,
    required DateTime recordedAtUtc,
    required AdherenceEventActor actor,
    required OccurrenceWindow newWindow,
    String? note,
  }) {
    if (newWindow.scheduledFor == occurrence.originalScheduledFor) {
      throw const SmartRoutineValidationException(
        'ineffective_reschedule',
        'A reschedule must change the effective target.',
      );
    }
    return _event(
      occurrence: occurrence,
      eventId: eventId,
      type: AdherenceEventType.rescheduled,
      occurredAtUtc: occurredAtUtc,
      recordedAtUtc: recordedAtUtc,
      actor: actor,
      rescheduledWindow: newWindow,
      note: note,
    );
  }

  RoutineAdherenceEvent correction({
    required RoutineOccurrence occurrence,
    required RoutineAdherenceEventId eventId,
    required RoutineAdherenceEvent referencedEvent,
    required AdherenceCorrectionAction action,
    required DateTime occurredAtUtc,
    required DateTime recordedAtUtc,
    required AdherenceEventActor actor,
    AdherenceEventType? replacementType,
    DateTime? replacementOccurredAtUtc,
    OccurrenceWindow? rescheduledWindow,
    String? note,
  }) {
    _ensureBelongs(occurrence, referencedEvent);
    return _event(
      occurrence: occurrence,
      eventId: eventId,
      type: AdherenceEventType.correction,
      occurredAtUtc: occurredAtUtc,
      recordedAtUtc: recordedAtUtc,
      actor: actor,
      referencedEventId: referencedEvent.eventId,
      correctionAction: action,
      replacementType: replacementType,
      replacementOccurredAtUtc: replacementOccurredAtUtc,
      rescheduledWindow: rescheduledWindow,
      note: note,
    );
  }

  RoutineAdherenceEvent _event({
    required RoutineOccurrence occurrence,
    required RoutineAdherenceEventId eventId,
    required AdherenceEventType type,
    required DateTime occurredAtUtc,
    required DateTime recordedAtUtc,
    required AdherenceEventActor actor,
    RoutineAdherenceEventId? referencedEventId,
    AdherenceCorrectionAction? correctionAction,
    AdherenceEventType? replacementType,
    DateTime? replacementOccurredAtUtc,
    OccurrenceWindow? rescheduledWindow,
    String? note,
    DoseValue? actualDose,
  }) => RoutineAdherenceEvent(
    eventId: eventId,
    occurrenceId: occurrence.occurrenceId,
    routineId: occurrence.routineId,
    planId: occurrence.planId,
    scheduleId: occurrence.scheduleId,
    type: type,
    occurredAtUtc: occurredAtUtc,
    recordedAtUtc: recordedAtUtc,
    actor: actor,
    referencedEventId: referencedEventId,
    correctionAction: correctionAction,
    replacementType: replacementType,
    replacementOccurredAtUtc: replacementOccurredAtUtc,
    rescheduledWindow: rescheduledWindow,
    note: note,
    actualDose: actualDose,
  );

  void _ensureBelongs(
    RoutineOccurrence occurrence,
    RoutineAdherenceEvent event,
  ) {
    if (event.occurrenceId != occurrence.occurrenceId ||
        event.routineId != occurrence.routineId ||
        event.planId != occurrence.planId ||
        event.scheduleId != occurrence.scheduleId) {
      throw const SmartRoutineValidationException(
        'foreign_adherence_event',
        'The referenced event does not belong to the occurrence.',
      );
    }
  }
}
