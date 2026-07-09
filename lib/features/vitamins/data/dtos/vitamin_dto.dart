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
    required this.status,
    required this.syncMetadata,
  });

  final String id;
  final String name;
  final int hour;
  final int minute;
  final VitaminStatus status;
  final SyncMetadata syncMetadata;

  Vitamin toEntity() {
    final vitaminName = VitaminName.create(name);
    final scheduleTime = VitaminScheduleTime.create(hour: hour, minute: minute);

    if (vitaminName == null || scheduleTime == null) {
      throw FormatException('Vitamina local inválida: $id');
    }

    return Vitamin(
      id: id,
      name: vitaminName,
      scheduleTime: scheduleTime,
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
      status: vitamin.status,
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
      status: VitaminStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => VitaminStatus.pending,
      ),
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
