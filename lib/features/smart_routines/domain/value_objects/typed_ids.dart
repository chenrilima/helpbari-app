import '../errors/smart_routine_validation_exception.dart';

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
);

String _validatedUuid(String value, String code) {
  final normalized = value.trim().toLowerCase();
  if (!_uuidPattern.hasMatch(normalized)) {
    throw SmartRoutineValidationException(code, 'A valid UUID is required.');
  }
  return normalized;
}

abstract class RoutineUuidValue {
  RoutineUuidValue(String value, String code)
    : value = _validatedUuid(value, code);

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other.runtimeType == runtimeType &&
          other is RoutineUuidValue &&
          value == other.value;

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() => value;
}

final class RoutineId extends RoutineUuidValue {
  RoutineId(String value) : super(value, 'invalid_routine_id');
}

final class RoutinePlanId extends RoutineUuidValue {
  RoutinePlanId(String value) : super(value, 'invalid_routine_plan_id');
}

final class RoutineScheduleId extends RoutineUuidValue {
  RoutineScheduleId(String value) : super(value, 'invalid_routine_schedule_id');
}

final class RoutineOccurrenceId extends RoutineUuidValue {
  RoutineOccurrenceId(String value)
    : super(value, 'invalid_routine_occurrence_id');
}

final class RoutineAdherenceEventId extends RoutineUuidValue {
  RoutineAdherenceEventId(String value)
    : super(value, 'invalid_routine_adherence_event_id');
}

final class RoutinePauseId extends RoutineUuidValue {
  RoutinePauseId(String value) : super(value, 'invalid_routine_pause_id');
}

final class PrescriptionId extends RoutineUuidValue {
  PrescriptionId(String value) : super(value, 'invalid_prescription_id');
}

final class PrescriptionItemId extends RoutineUuidValue {
  PrescriptionItemId(String value)
    : super(value, 'invalid_prescription_item_id');
}
