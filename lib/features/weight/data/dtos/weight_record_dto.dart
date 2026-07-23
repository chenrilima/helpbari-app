import '../../../../core/database/database.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/sync/sync.dart';
import '../../domain/entities/entities.dart';
import '../../domain/value_objects/value_objects.dart';

class WeightRecordDto {
  const WeightRecordDto({
    required this.id,
    required this.weight,
    required this.recordedAt,
    required this.syncMetadata,
    this.notes,
  });

  final String id;
  final double weight;
  final DateTime recordedAt;
  final String? notes;
  final SyncMetadata syncMetadata;

  WeightRecord toEntity({ClockService clock = const AppClockService()}) {
    final value = WeightValue.create(weight);
    final noteValue = notes == null ? null : Notes.create(notes!);

    if (value == null) {
      throw FormatException('Registro de peso local inválido: $id');
    }

    return WeightRecord(
      id: id,
      weight: value,
      recordedAt: RecordedAt(recordedAt, clock: clock),
      notes: noteValue,
    );
  }

  LocalDatabaseRecord toRecord() {
    return LocalDatabaseRecord(
      metadata: syncMetadata,
      data: {
        'weight': weight,
        'recordedAt': recordedAt.toIso8601String(),
        'notes': notes,
      },
    );
  }

  static WeightRecordDto fromEntity(
    WeightRecord record, {
    required DateTime now,
    SyncMetadata? previousMetadata,
  }) {
    final syncStatus = _nextSyncStatus(previousMetadata?.syncStatus);

    return WeightRecordDto(
      id: record.id,
      weight: record.weight.value,
      recordedAt: record.recordedAt.value,
      notes: record.notes?.value,
      syncMetadata: SyncMetadata(
        id: record.id,
        userId: previousMetadata?.userId,
        createdAt: previousMetadata?.createdAt ?? now,
        updatedAt: now,
        syncStatus: syncStatus,
      ),
    );
  }

  Map<String, dynamic> toSupabaseInsert({required String userId}) => {
    'id': id,
    'user_id': userId,
    'weight_kg': weight,
    'recorded_at': recordedAt.toUtc().toIso8601String(),
    'notes': notes,
    'created_at': syncMetadata.createdAt.toUtc().toIso8601String(),
    'updated_at': syncMetadata.updatedAt.toUtc().toIso8601String(),
    'deleted_at': syncMetadata.deletedAt?.toUtc().toIso8601String(),
  };

  Map<String, dynamic> toSupabaseUpdate({required String userId}) =>
      toSupabaseInsert(userId: userId)..remove('created_at');

  factory WeightRecordDto.fromSupabaseRow(Map<String, dynamic> row) {
    return WeightRecordDto(
      id: row['id'] as String,
      weight: (row['weight_kg'] as num).toDouble(),
      recordedAt: DateTime.parse(row['recorded_at'] as String),
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
  }

  static WeightRecordDto fromRecord(LocalDatabaseRecord record) {
    final data = record.data;

    return WeightRecordDto(
      id: record.id,
      weight: (data['weight'] as num).toDouble(),
      recordedAt: DateTime.parse(data['recordedAt'] as String),
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
