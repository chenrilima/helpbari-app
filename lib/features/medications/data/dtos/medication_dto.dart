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
    required this.syncMetadata,
    this.dosage,
    this.notes,
  });

  final String id;
  final String name;
  final int hour;
  final int minute;
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
    );
  }

  LocalDatabaseRecord toRecord() {
    return LocalDatabaseRecord(
      metadata: syncMetadata,
      data: {
        'name': name,
        'hour': hour,
        'minute': minute,
        'status': MedicationStatus.pending.name,
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
      dosage: data['dosage'] as String?,
      notes: data['notes'] as String?,
      syncMetadata: record.metadata,
    );
  }

  Map<String, dynamic> toSupabaseRow({required String userId}) => {
    'id': id,
    'user_id': userId,
    'name': name,
    'schedule_hour': hour,
    'schedule_minute': minute,
    'dosage': dosage,
    'notes': notes,
    'status': MedicationStatus.pending.name,
    'created_at': syncMetadata.createdAt.toUtc().toIso8601String(),
    'updated_at': syncMetadata.updatedAt.toUtc().toIso8601String(),
    'deleted_at': syncMetadata.deletedAt?.toUtc().toIso8601String(),
  };
  factory MedicationDto.fromSupabaseRow(Map<String, dynamic> row) =>
      MedicationDto(
        id: row['id'] as String,
        name: row['name'] as String,
        hour: row['schedule_hour'] as int,
        minute: row['schedule_minute'] as int,
        dosage: row['dosage'] as String?,
        notes: row['notes'] as String?,
        syncMetadata: SyncMetadata(
          id: row['id'] as String,
          userId: row['user_id'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
          updatedAt: DateTime.parse(row['updated_at'] as String),
          deletedAt: row['deleted_at'] == null
              ? null
              : DateTime.parse(row['deleted_at'] as String),
        syncStatus: SyncStatus.synced,
        serverRevision: row['server_revision'] as int?,
        ),
      );

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
