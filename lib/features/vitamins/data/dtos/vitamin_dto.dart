import '../../../../core/database/database.dart';
import '../../../../core/sync/sync.dart';
import '../../domain/entities/entities.dart';
import '../../domain/value_objects/value_objects.dart';

class VitaminDto {
  const VitaminDto({
    required this.id,
    required this.name,
    required this.hour,
    required this.minute,
    required this.syncMetadata,
  });

  final String id;
  final String name;
  final int hour;
  final int minute;
  final SyncMetadata syncMetadata;

  Vitamin toEntity() {
    final vitaminName = VitaminName.create(name);
    final scheduleTime = VitaminScheduleTime.create(hour: hour, minute: minute);

    if (vitaminName == null || scheduleTime == null) {
      throw FormatException('Vitamina local inválida: $id');
    }

    return Vitamin(id: id, name: vitaminName, scheduleTime: scheduleTime);
  }

  LocalDatabaseRecord toRecord() {
    return LocalDatabaseRecord(
      metadata: syncMetadata,
      data: {
        'name': name,
        'hour': hour,
        'minute': minute,
        'status': VitaminStatus.pending.name,
      },
    );
  }

  static VitaminDto fromEntity(
    Vitamin vitamin, {
    required DateTime now,
    SyncMetadata? previousMetadata,
  }) {
    return VitaminDto(
      id: vitamin.id,
      name: vitamin.name.value,
      hour: vitamin.scheduleTime.hour,
      minute: vitamin.scheduleTime.minute,
      syncMetadata: SyncMetadata(
        id: vitamin.id,
        userId: previousMetadata?.userId,
        createdAt: previousMetadata?.createdAt ?? now,
        updatedAt: now,
        syncStatus: _nextSyncStatus(previousMetadata?.syncStatus),
      ),
    );
  }

  static VitaminDto fromRecord(LocalDatabaseRecord record) {
    final data = record.data;

    return VitaminDto(
      id: record.id,
      name: data['name'] as String,
      hour: data['hour'] as int,
      minute: data['minute'] as int,
      syncMetadata: record.metadata,
    );
  }

  Map<String, dynamic> toSupabaseRow({required String userId}) => {
    'id': id,
    'user_id': userId,
    'name': name,
    'schedule_hour': hour,
    'schedule_minute': minute,
    // Kept only because the initial schema requires the legacy column.
    'status': VitaminStatus.pending.name,
    'created_at': syncMetadata.createdAt.toUtc().toIso8601String(),
    'updated_at': syncMetadata.updatedAt.toUtc().toIso8601String(),
    'deleted_at': syncMetadata.deletedAt?.toUtc().toIso8601String(),
  };

  factory VitaminDto.fromSupabaseRow(Map<String, dynamic> row) => VitaminDto(
    id: row['id'] as String,
    name: row['name'] as String,
    hour: row['schedule_hour'] as int,
    minute: row['schedule_minute'] as int,
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
