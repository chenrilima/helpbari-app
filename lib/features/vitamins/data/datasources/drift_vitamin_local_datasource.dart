import 'package:drift/drift.dart' show Value;
import '../../../../core/database/drift/app_database.dart';
import '../../../../core/database/drift/daos/vitamin_dao.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/sync/sync.dart';
import '../dtos/vitamin_dto.dart';

class DriftVitaminLocalDatasource {
  const DriftVitaminLocalDatasource({
    required VitaminDao dao,
    required ClockService clock,
    required this.userId,
  }) : _dao = dao,
       _clock = clock;
  final VitaminDao _dao;
  final ClockService _clock;
  final String userId;
  bool get canSync => userId != 'anonymous';
  Future<List<VitaminDto>> getAll() async =>
      (await _dao.getActiveByUser(userId)).map(_fromRow).toList();
  Future<VitaminDto?> getById(String id) async {
    final row = await _dao.getByUserAndId(userId, id);
    return row == null ? null : _fromRow(row);
  }

  Future<void> save(VitaminDto value) async {
    final old = await getById(value.id);
    final dto = VitaminDto.fromEntity(
      value.toEntity(),
      now: _clock.now(),
      previousMetadata: old?.syncMetadata.copyWith(userId: userId),
    );
    await _dao.upsert(_companion(dto));
  }

  Future<void> delete(String id) async {
    final old = await getById(id);
    if (old == null) return;
    final now = _clock.now();
    await _dao.upsert(
      _companion(
        VitaminDto(
          id: old.id,
          name: old.name,
          hour: old.hour,
          minute: old.minute,
          syncMetadata: old.syncMetadata.copyWith(
            updatedAt: now,
            deletedAt: now,
            syncStatus: SyncStatus.pendingDelete,
          ),
        ),
      ),
    );
  }

  Future<List<VitaminDto>> pendingSync() async => canSync
      ? (await _dao.getPendingForSync(userId)).map(_pending).toList()
      : const [];
  Future<VitaminDto?> pendingById(String id) async {
    if (!canSync) return null;
    final row = await _dao.getByUserAndId(userId, id);
    return row == null || row.syncStatus == 'synced' ? null : _pending(row);
  }

  Future<void> applyRemote(VitaminDto remote) async {
    if (!canSync || remote.syncMetadata.userId != userId) return;
    final local = await getById(remote.id);
    if (local != null &&
        !remote.syncMetadata.updatedAt.isAfter(local.syncMetadata.updatedAt)) {
      return;
    }
    await _dao.upsert(_companion(remote));
  }

  Future<void> applyRemoteAndMarkSynced(VitaminDto remote) =>
      _dao.inTransaction(() async {
        await applyRemote(remote);
        await markSynced(remote.id);
      });
  Future<void> markSynced(String id) async {
    final row = await _dao.getByUserAndId(userId, id);
    if (row != null) {
      await _dao.upsert(_syncCopy(row, SyncStatus.synced, 0));
    }
  }

  Future<void> markFailed(String id, String error) async {
    final row = await _dao.getByUserAndId(userId, id);
    if (row != null) {
      await _dao.upsert(
        _syncCopy(
          row,
          SyncStatus.failed,
          row.syncAttempts + 1,
          previous: row.previousSyncStatus ?? row.syncStatus,
          error: error,
        ),
      );
    }
  }

  Future<DateTime?> getLastPullAt(String key) =>
      _dao.getLastPullAt(userId, key);
  Future<void> saveCursor(String key, DateTime at) =>
      _dao.saveCursor(userId, key, at);
  VitaminDto _pending(VitaminRecord row) {
    final dto = _fromRow(row);
    return row.syncStatus == 'failed'
        ? VitaminDto(
            id: dto.id,
            name: dto.name,
            hour: dto.hour,
            minute: dto.minute,
            syncMetadata: dto.syncMetadata.copyWith(
              syncStatus: SyncStatus.fromName(row.previousSyncStatus),
            ),
          )
        : dto;
  }

  VitaminDto _fromRow(VitaminRecord row) => VitaminDto(
    id: row.id,
    name: row.name,
    hour: row.scheduleHour,
    minute: row.scheduleMinute,
    syncMetadata: SyncMetadata(
      id: row.id,
      userId: row.userId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
      syncStatus: SyncStatus.fromName(row.syncStatus),
    ),
  );
  VitaminRecordsCompanion _companion(VitaminDto dto) =>
      VitaminRecordsCompanion.insert(
        id: dto.id,
        userId: userId,
        name: dto.name,
        scheduleHour: dto.hour,
        scheduleMinute: dto.minute,
        createdAt: dto.syncMetadata.createdAt,
        updatedAt: dto.syncMetadata.updatedAt,
        deletedAt: Value(dto.syncMetadata.deletedAt),
        syncStatus: dto.syncMetadata.syncStatus.name,
      );
  VitaminRecordsCompanion _syncCopy(
    VitaminRecord row,
    SyncStatus status,
    int attempts, {
    String? previous,
    String? error,
  }) => VitaminRecordsCompanion(
    id: Value(row.id),
    userId: Value(row.userId),
    name: Value(row.name),
    scheduleHour: Value(row.scheduleHour),
    scheduleMinute: Value(row.scheduleMinute),
    createdAt: Value(row.createdAt),
    updatedAt: Value(row.updatedAt),
    deletedAt: Value(row.deletedAt),
    syncStatus: Value(status.name),
    previousSyncStatus: Value(previous),
    syncAttempts: Value(attempts),
    lastSyncError: Value(error),
  );
}
