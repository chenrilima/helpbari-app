import '../../../../core/domain/entity.dart';
import '../value_objects/value_objects.dart';

class Medication extends Entity {
  const Medication({
    required this.id,
    required this.name,
    required this.scheduleTime,
    this.dosage,
    this.notes,
    this.status = MedicationStatus.pending,
  });

  @override
  final String id;

  final MedicationName name;
  final MedicationScheduleTime scheduleTime;
  final String? dosage;
  final String? notes;
  final MedicationStatus status;

  bool get isPending => status == MedicationStatus.pending;

  bool get isTaken => status == MedicationStatus.taken;

  bool get isSkipped => status == MedicationStatus.skipped;

  String get formattedName => name.value;

  String get formattedTime => scheduleTime.formatted;

  String get statusDescription {
    return switch (status) {
      MedicationStatus.pending => 'Pendente',
      MedicationStatus.taken => 'Tomado',
      MedicationStatus.skipped => 'Ignorado',
    };
  }

  Medication markAsTaken() {
    return copyWith(status: MedicationStatus.taken);
  }

  Medication markAsSkipped() {
    return copyWith(status: MedicationStatus.skipped);
  }

  Medication copyWith({
    MedicationName? name,
    MedicationScheduleTime? scheduleTime,
    String? dosage,
    String? notes,
    MedicationStatus? status,
  }) {
    return Medication(
      id: id,
      name: name ?? this.name,
      scheduleTime: scheduleTime ?? this.scheduleTime,
      dosage: dosage ?? this.dosage,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }
}
