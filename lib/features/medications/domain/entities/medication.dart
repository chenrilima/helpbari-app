import '../../../../core/domain/entity.dart';
import '../value_objects/value_objects.dart';

class Medication extends Entity {
  const Medication({
    required this.id,
    required this.name,
    required this.scheduleTime,
    this.dosage,
    this.notes,
  });

  @override
  final String id;

  final MedicationName name;
  final MedicationScheduleTime scheduleTime;
  final String? dosage;
  final String? notes;

  String get formattedName => name.value;

  String get formattedTime => scheduleTime.formatted;

  Medication copyWith({
    MedicationName? name,
    MedicationScheduleTime? scheduleTime,
    String? dosage,
    String? notes,
  }) {
    return Medication(
      id: id,
      name: name ?? this.name,
      scheduleTime: scheduleTime ?? this.scheduleTime,
      dosage: dosage ?? this.dosage,
      notes: notes ?? this.notes,
    );
  }
}
