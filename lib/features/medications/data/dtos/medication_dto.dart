import '../../../../core/database/database.dart';
import '../../../../core/sync/sync.dart';
import '../../domain/entities/entities.dart';
import '../../domain/value_objects/value_objects.dart';

class MedicationDto {
  const MedicationDto({
    required this.id,
    required this.name,
    required this.hour,
    required this.minute,
    required this.status,
    required this.syncMetadata,
    this.dosage,
    this.notes,
  });

  final String id;
  final String name;
  final int hour;
  final int minute;
  final MedicationStatus status;
  final String? dosage;
  final String? notes;
  final SyncMetadata syncMetadata;

  Medication toEntity() {
    final medicationName = MedicationName.create(name);
    final scheduleTime = MedicationScheduleTime.create(
      hour: hour,
      minute: minute,
    );

    if (medicationName == null || scheduleTime == null) {
      throw FormatException('Medicamento local inválido: $id');
    }

    return Medication(
      id: id,
      name: medicationName,
      scheduleTime: scheduleTime,
      dosage: dosage,
      notes: notes,
      status: status,
    );
  }

  LocalDatabaseRecord toRecord() {
    return LocalDatabaseRecord(
      metadata: syncMetadata,
      data: {
        'name': name,
        'hour': hour,
        'minute': minute,
        'status': status.name,
        'dosage': dosage,
        'notes': notes,
      },
    );
  }

  static MedicationDto fromEntity(
    Medication medication, {
    required DateTime now,
    SyncMetadata? previousMetadata,
  }) {
    return MedicationDto(
      id: medication.id,
      name: medication.name.value,
      hour: medication.scheduleTime.hour,
      minute: medication.scheduleTime.minute,
      status: medication.status,
      dosage: medication.dosage,
      notes: medication.notes,
      syncMetadata: SyncMetadata(
        id: medication.id,
        userId: previousMetadata?.userId,
        createdAt: previousMetadata?.createdAt ?? now,
        updatedAt: now,
        syncStatus: _nextSyncStatus(previousMetadata?.syncStatus),
      ),
    );
  }

  static MedicationDto fromRecord(LocalDatabaseRecord record) {
    final data = record.data;

    return MedicationDto(
      id: record.id,
      name: data['name'] as String,
      hour: data['hour'] as int,
      minute: data['minute'] as int,
      status: MedicationStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => MedicationStatus.pending,
      ),
      dosage: data['dosage'] as String?,
      notes: data['notes'] as String?,
      syncMetadata: record.metadata,
    );
  }

  static SyncStatus _nextSyncStatus(SyncStatus? currentStatus) {
    return switch (currentStatus) {
      SyncStatus.synced => SyncStatus.pendingUpdate,
      SyncStatus.failed => SyncStatus.pendingUpdate,
      SyncStatus.pendingDelete => SyncStatus.pendingUpdate,
      SyncStatus.pendingCreate => SyncStatus.pendingCreate,
      SyncStatus.pendingUpdate => SyncStatus.pendingUpdate,
      null => SyncStatus.pendingCreate,
    };
  }
}
