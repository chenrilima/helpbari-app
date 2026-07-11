import 'package:drift/drift.dart' show Value;

import '../../../../core/database/drift/app_database.dart';
import '../../../../core/database/drift/consistency/water_local_snapshot.dart';
import '../../../../core/database/drift/daos/water_dao.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/sync/sync.dart';
import '../dtos/water_record_dto.dart';

class DriftWaterLocalDatasource {
  const DriftWaterLocalDatasource({
    required WaterDao dao,
    required ClockService clock,
    required this.userId,
  }) : _dao = dao,
       _clock = clock;

  final WaterDao _dao;
  final ClockService _clock;
  final String userId;

  bool get canSync => userId != anonymousWaterUserId;

  Future<List<WaterRecordDto>> getHistory() async =>
      (await _dao.getActiveByUser(userId)).map(_fromDrift).toList();

  Future<WaterRecordDto?> getById(String id) async {
    final row = await _dao.getByUserAndId(userId, id);
    return row == null ? null : _fromDrift(row);
  }

  Future<void> save(WaterRecordDto record) async {
    final previous = await getById(record.id);
    final dto = WaterRecordDto.fromEntity(
      record.toEntity(clock: _clock),
      now: _clock.now(),
      userId: userId,
      previousMetadata: previous?.syncMetadata,
    );
    await _dao.upsert(_companion(dto));
  }

  Future<void> delete(String id) async {
    final previous = await getById(id);
    if (previous == null) return;
    final now = _clock.now();
    await _dao.upsert(
      _companion(
        WaterRecordDto(
          id: previous.id,
          amountInMl: previous.amountInMl,
          recordedAt: previous.recordedAt,
          syncMetadata: previous.syncMetadata.copyWith(
            updatedAt: now,
            deletedAt: now,
            syncStatus: SyncStatus.pendingDelete,
          ),
        ),
      ),
    );
  }

  Future<List<WaterRecordDto>> pendingSync() async {
    if (!canSync) return const [];
    return (await _dao.getPendingForSync(userId)).map(_pendingDto).toList();
  }

  Future<WaterRecordDto?> pendingById(String id) async {
    if (!canSync) return null;
    final row = await _dao.getByUserAndId(userId, id);
    if (row == null || row.syncStatus == SyncStatus.synced.name) return null;
    return _pendingDto(row);
  }

  Future<void> applyRemote(WaterRecordDto remote) async {
    if (!canSync || remote.syncMetadata.userId != userId) return;
    final local = await getById(remote.id);
    if (local != null &&
        !remote.syncMetadata.updatedAt.isAfter(local.syncMetadata.updatedAt)) {
      return;
    }
    await _dao.upsert(_companion(remote));
  }

  Future<void> applyRemoteAndMarkSynced(WaterRecordDto remote) {
    return _dao.inTransaction(() async {
      await applyRemote(remote);
      await markSynced(remote.id);
    });
  }

  Future<void> markSynced(String id) async {
    final row = await _dao.getByUserAndId(userId, id);
    if (row == null) return;
    await _dao.upsert(
      WaterRecordsCompanion(
        id: Value(row.id),
        userId: Value(row.userId),
        amountMl: Value(row.amountMl),
        recordedAt: Value(row.recordedAt),
        createdAt: Value(row.createdAt),
        updatedAt: Value(row.updatedAt),
        deletedAt: Value(row.deletedAt),
        syncStatus: Value(SyncStatus.synced.name),
        previousSyncStatus: const Value(null),
        syncAttempts: const Value(0),
        lastSyncError: const Value(null),
      ),
    );
  }

  Future<void> markFailed(String id, String message) async {
    final row = await _dao.getByUserAndId(userId, id);
    if (row == null) return;
    await _dao.upsert(
      WaterRecordsCompanion(
        id: Value(row.id),
        userId: Value(row.userId),
        amountMl: Value(row.amountMl),
        recordedAt: Value(row.recordedAt),
        createdAt: Value(row.createdAt),
        updatedAt: Value(row.updatedAt),
        deletedAt: Value(row.deletedAt),
        syncStatus: Value(SyncStatus.failed.name),
        previousSyncStatus: Value(row.previousSyncStatus ?? row.syncStatus),
        syncAttempts: Value(row.syncAttempts + 1),
        lastSyncError: Value(message),
      ),
    );
  }

  Future<void> saveBatch(Iterable<WaterRecordDto> records) =>
      _dao.upsertAll(records.map(_companion));

  Future<T> inTransaction<T>(Future<T> Function() action) =>
      _dao.inTransaction(action);

  Future<DateTime?> getLastPullAt(String repositoryKey) =>
      _dao.getLastPullAt(userId, repositoryKey);

  Future<void> saveCursor(String repositoryKey, DateTime completedAt) =>
      _dao.saveCursor(userId, repositoryKey, completedAt);

  WaterRecordDto _pendingDto(WaterRecord row) {
    final dto = _fromDrift(row);
    if (row.syncStatus != SyncStatus.failed.name) return dto;
    return WaterRecordDto(
      id: dto.id,
      amountInMl: dto.amountInMl,
      recordedAt: dto.recordedAt,
      syncMetadata: dto.syncMetadata.copyWith(
        syncStatus: SyncStatus.fromName(row.previousSyncStatus),
      ),
    );
  }

  WaterRecordDto _fromDrift(WaterRecord row) => WaterRecordDto(
    id: row.id,
    amountInMl: row.amountMl,
    recordedAt: row.recordedAt,
    syncMetadata: SyncMetadata(
      id: row.id,
      userId: row.userId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
      syncStatus: SyncStatus.fromName(row.syncStatus),
    ),
  );

  WaterRecordsCompanion _companion(WaterRecordDto dto) =>
      WaterRecordsCompanion.insert(
        id: dto.id,
        userId: userId,
        amountMl: dto.amountInMl,
        recordedAt: dto.recordedAt,
        createdAt: dto.syncMetadata.createdAt,
        updatedAt: dto.syncMetadata.updatedAt,
        deletedAt: Value(dto.syncMetadata.deletedAt),
        syncStatus: dto.syncMetadata.syncStatus.name,
      );
}
