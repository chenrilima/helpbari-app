import 'package:drift/drift.dart' show Value;

import '../../../../core/database/drift/app_database.dart';
import '../../../../core/database/drift/daos/weight_dao.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/sync/sync.dart';
import '../dtos/weight_record_dto.dart';

const anonymousWeightUserId = 'anonymous';

class DriftWeightLocalDatasource {
  const DriftWeightLocalDatasource({
    required WeightDao dao,
    required ClockService clock,
    required this.userId,
  }) : _dao = dao,
       _clock = clock;
  final WeightDao _dao;
  final ClockService _clock;
  final String userId;
  bool get canSync => userId != anonymousWeightUserId;

  Future<List<WeightRecordDto>> getHistory() async =>
      (await _dao.getActiveByUser(userId)).map(_fromDrift).toList();
  Future<WeightRecordDto?> getById(String id) async {
    final row = await _dao.getByUserAndId(userId, id);
    return row == null ? null : _fromDrift(row);
  }

  Future<void> save(WeightRecordDto record) async {
    final previous = await getById(record.id);
    final dto = WeightRecordDto.fromEntity(
      record.toEntity(clock: _clock),
      now: _clock.now(),
      previousMetadata: previous?.syncMetadata.copyWith(userId: userId),
    );
    await _dao.upsert(_companion(dto));
  }

  Future<void> delete(String id) async {
    final previous = await getById(id);
    if (previous == null) return;
    final now = _clock.now();
    await _dao.upsert(
      _companion(
        WeightRecordDto(
          id: previous.id,
          weight: previous.weight,
          recordedAt: previous.recordedAt,
          notes: previous.notes,
          syncMetadata: previous.syncMetadata.copyWith(
            updatedAt: now,
            deletedAt: now,
            syncStatus: SyncStatus.pendingDelete,
          ),
        ),
      ),
    );
  }

  Future<List<WeightRecordDto>> pendingSync() async => canSync
      ? (await _dao.getPendingForSync(userId)).map(_pendingDto).toList()
      : const [];
  Future<WeightRecordDto?> pendingById(String id) async {
    if (!canSync) return null;
    final row = await _dao.getByUserAndId(userId, id);
    if (row == null || row.syncStatus == SyncStatus.synced.name) return null;
    return _pendingDto(row);
  }

  Future<void> applyRemote(WeightRecordDto remote) async {
    if (!canSync || remote.syncMetadata.userId != userId) return;
    final local = await getById(remote.id);
    if (local != null &&
        !remote.syncMetadata.updatedAt.isAfter(local.syncMetadata.updatedAt)) {
      return;
    }
    await _dao.upsert(_companion(remote));
  }

  Future<void> applyRemoteAndMarkSynced(WeightRecordDto remote) =>
      _dao.inTransaction(() async {
        await applyRemote(remote);
        await markSynced(remote.id);
      });
  Future<void> markSynced(String id) => _updateSync(id, SyncStatus.synced);
  Future<void> markFailed(String id, String message) async {
    final row = await _dao.getByUserAndId(userId, id);
    if (row == null) return;
    await _dao.upsert(
      _copy(
        row,
        status: SyncStatus.failed,
        previousStatus: row.previousSyncStatus ?? row.syncStatus,
        attempts: row.syncAttempts + 1,
        error: message,
      ),
    );
  }

  Future<void> _updateSync(String id, SyncStatus status) async {
    final row = await _dao.getByUserAndId(userId, id);
    if (row == null) return;
    await _dao.upsert(_copy(row, status: status, attempts: 0));
  }

  Future<DateTime?> getLastPullAt(String key) =>
      _dao.getLastPullAt(userId, key);
  Future<void> saveCursor(String key, DateTime at) =>
      _dao.saveCursor(userId, key, at);

  WeightRecordDto _pendingDto(WeightRecord row) {
    final dto = _fromDrift(row);
    return row.syncStatus == SyncStatus.failed.name
        ? WeightRecordDto(
            id: dto.id,
            weight: dto.weight,
            recordedAt: dto.recordedAt,
            notes: dto.notes,
            syncMetadata: dto.syncMetadata.copyWith(
              syncStatus: SyncStatus.fromName(row.previousSyncStatus),
            ),
          )
        : dto;
  }

  WeightRecordDto _fromDrift(WeightRecord row) => WeightRecordDto(
    id: row.id,
    weight: row.weightKg,
    recordedAt: row.recordedAt,
    notes: row.notes,
    syncMetadata: SyncMetadata(
      id: row.id,
      userId: row.userId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
      syncStatus: SyncStatus.fromName(row.syncStatus),
    ),
  );
  WeightRecordsCompanion _companion(WeightRecordDto dto) =>
      WeightRecordsCompanion.insert(
        id: dto.id,
        userId: userId,
        weightKg: dto.weight,
        recordedAt: dto.recordedAt,
        notes: Value(dto.notes),
        createdAt: dto.syncMetadata.createdAt,
        updatedAt: dto.syncMetadata.updatedAt,
        deletedAt: Value(dto.syncMetadata.deletedAt),
        syncStatus: dto.syncMetadata.syncStatus.name,
      );
  WeightRecordsCompanion _copy(
    WeightRecord row, {
    required SyncStatus status,
    String? previousStatus,
    required int attempts,
    String? error,
  }) => WeightRecordsCompanion(
    id: Value(row.id),
    userId: Value(row.userId),
    weightKg: Value(row.weightKg),
    recordedAt: Value(row.recordedAt),
    notes: Value(row.notes),
    createdAt: Value(row.createdAt),
    updatedAt: Value(row.updatedAt),
    deletedAt: Value(row.deletedAt),
    syncStatus: Value(status.name),
    previousSyncStatus: Value(previousStatus),
    syncAttempts: Value(attempts),
    lastSyncError: Value(error),
  );
}
