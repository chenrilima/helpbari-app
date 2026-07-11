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

  Map<String, dynamic> toSupabaseInsert({required String userId}) {
    return {
      'id': id,
      'user_id': userId,
      'amount_ml': amountInMl,
      'recorded_at': recordedAt.toIso8601String(),
      'created_at': syncMetadata.createdAt.toIso8601String(),
      'updated_at': syncMetadata.updatedAt.toIso8601String(),
      'deleted_at': syncMetadata.deletedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabaseUpdate({required String userId}) {
    return {
      'user_id': userId,
      'amount_ml': amountInMl,
      'recorded_at': recordedAt.toIso8601String(),
      'updated_at': syncMetadata.updatedAt.toIso8601String(),
      'deleted_at': syncMetadata.deletedAt?.toIso8601String(),
    };
  }

  static WaterRecordDto fromEntity(
    WaterRecord record, {
    required DateTime now,
    String? userId,
    SyncMetadata? previousMetadata,
  }) {
    final syncStatus = _nextSyncStatus(previousMetadata?.syncStatus);

    return WaterRecordDto(
      id: record.id,
      amountInMl: record.amount.valueInMl,
      recordedAt: record.recordedAt,
      syncMetadata: SyncMetadata(
        id: record.id,
        userId: previousMetadata?.userId ?? userId,
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

  static WaterRecordDto fromSupabaseRow(Map<String, dynamic> row) {
    final id = row['id'] as String;

    return WaterRecordDto(
      id: id,
      amountInMl: row['amount_ml'] as int,
      recordedAt: _dateTime(row['recorded_at']),
      syncMetadata: SyncMetadata(
        id: id,
        userId: row['user_id'] as String?,
        createdAt: _dateTime(row['created_at']),
        updatedAt: _dateTime(row['updated_at']),
        deletedAt: _nullableDateTime(row['deleted_at']),
        syncStatus: SyncStatus.synced,
      ),
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

  static DateTime _dateTime(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);

    throw FormatException('Data inválida para registro de água: $value');
  }

  static DateTime? _nullableDateTime(Object? value) {
    if (value == null) return null;
    if (value is String && value.isEmpty) return null;

    return _dateTime(value);
  }
}
