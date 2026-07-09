import '../../../../core/database/database.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/sync/sync.dart';
import '../../domain/entities/entities.dart';
import '../../domain/value_objects/value_objects.dart';

class WaterRecordDto {
  const WaterRecordDto({
    required this.id,
    required this.amountInMl,
    required this.recordedAt,
    required this.syncMetadata,
  });

  final String id;
  final int amountInMl;
  final DateTime recordedAt;
  final SyncMetadata syncMetadata;

  WaterRecord toEntity({ClockService clock = const AppClockService()}) {
    final amount = WaterAmount.create(amountInMl);

    if (amount == null) {
      throw FormatException('Registro de água local inválido: $id');
    }

    return WaterRecord(
      id: id,
      amount: amount,
      recordedAt: recordedAt,
      clock: clock,
    );
  }

  LocalDatabaseRecord toRecord() {
    return LocalDatabaseRecord(
      metadata: syncMetadata,
      data: {
        'amountInMl': amountInMl,
        'recordedAt': recordedAt.toIso8601String(),
      },
    );
  }

  static WaterRecordDto fromEntity(
    WaterRecord record, {
    required DateTime now,
    SyncMetadata? previousMetadata,
  }) {
    final syncStatus = _nextSyncStatus(previousMetadata?.syncStatus);

    return WaterRecordDto(
      id: record.id,
      amountInMl: record.amount.valueInMl,
      recordedAt: record.recordedAt,
      syncMetadata: SyncMetadata(
        id: record.id,
        userId: previousMetadata?.userId,
        createdAt: previousMetadata?.createdAt ?? now,
        updatedAt: now,
        syncStatus: syncStatus,
      ),
    );
  }

  static WaterRecordDto fromRecord(LocalDatabaseRecord record) {
    final data = record.data;

    return WaterRecordDto(
      id: record.id,
      amountInMl: data['amountInMl'] as int,
      recordedAt: DateTime.parse(data['recordedAt'] as String),
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
