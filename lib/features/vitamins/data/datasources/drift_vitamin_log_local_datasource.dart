import 'package:drift/drift.dart' show Value;
import '../../../../core/database/drift/app_database.dart';
import '../../../../core/database/drift/daos/vitamin_log_dao.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/services/uuid_service.dart';
import '../../../../core/sync/sync.dart';
import '../../domain/value_objects/vitamin_status.dart';
import '../dtos/vitamin_log_dto.dart';

class DriftVitaminLogLocalDatasource {
  const DriftVitaminLogLocalDatasource({
    required VitaminLogDao dao,
    required ClockService clock,
    required UuidService uuid,
    required this.userId,
  }) : _dao = dao,
       _clock = clock,
       _uuid = uuid;
  final VitaminLogDao _dao;
  final ClockService _clock;
  final UuidService _uuid;
  final String userId;
  bool get canSync => userId != 'anonymous';
  DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
  Future<List<VitaminLogDto>> getByPeriod(DateTime start, DateTime end) async =>
      (await _dao.getByPeriod(
        userId,
        _day(start),
        _day(end),
      )).map(_fromRow).toList();
  Future<VitaminLogDto> setStatus({
    required String vitaminId,
    required DateTime date,
    required VitaminStatus status,
  }) async {
    final day = _day(date);
    final row = await _dao.getByVitaminAndDate(userId, vitaminId, day);
    final now = _clock.now();
    final id = row?.id ?? _uuid.generate();
    if (id.isEmpty) {
      throw StateError('VitaminLog requires a non-empty id.');
    }
    final dto = VitaminLogDto(
      id: id,
      vitaminId: vitaminId,
      date: day,
      status: status,
      syncMetadata: SyncMetadata(
        id: id,
        userId: userId,
        createdAt: row?.createdAt ?? now,
        updatedAt: now,
        syncStatus: row == null
            ? SyncStatus.pendingCreate
            : SyncStatus.pendingUpdate,
      ),
    );
    await _dao.upsert(_companion(dto));
    return dto;
  }

  Future<void> deleteForVitamin(String vitaminId) async {
    final rows = await _dao.getByPeriod(userId, DateTime(1970), DateTime(9999));
    final now = _clock.now();
    for (final row in rows.where((r) => r.vitaminId == vitaminId)) {
      await _dao.upsert(
        _copy(row, status: SyncStatus.pendingDelete, deletedAt: now),
      );
    }
  }

  Future<List<VitaminLogDto>> pendingSync() async => canSync
      ? (await _dao.getPendingForSync(userId)).map(_pending).toList()
      : const [];
  Future<VitaminLogDto?> pendingById(String id) async {
    if (!canSync) return null;
    final row = await _dao.getByUserAndId(userId, id);
    return row == null || row.syncStatus == 'synced' ? null : _pending(row);
  }

  Future<void> applyRemote(VitaminLogDto remote) async {
    if (!canSync || remote.syncMetadata.userId != userId) return;
    final local = await _dao.getByUserAndId(userId, remote.id);
    if (local != null &&
        !remote.syncMetadata.updatedAt.isAfter(local.updatedAt)) {
      return;
    }
    await _dao.upsert(_companion(remote));
  }

  Future<void> applyRemoteAndMarkSynced(VitaminLogDto remote) =>
      _dao.inTransaction(() async {
        await applyRemote(remote);
        await markSynced(remote.id);
      });
  Future<void> markSynced(String id) async {
    final row = await _dao.getByUserAndId(userId, id);
    if (row != null) {
      await _dao.upsert(_copy(row, status: SyncStatus.synced, attempts: 0));
    }
  }

  Future<void> markFailed(String id, String error) async {
    final row = await _dao.getByUserAndId(userId, id);
    if (row != null) {
      await _dao.upsert(
        _copy(
          row,
          status: SyncStatus.failed,
          previous: row.previousSyncStatus ?? row.syncStatus,
          attempts: row.syncAttempts + 1,
          error: error,
        ),
      );
    }
  }

  Future<DateTime?> getLastPullAt(String key) =>
      _dao.getLastPullAt(userId, key);
  Future<void> saveCursor(String key, DateTime at) =>
      _dao.saveCursor(userId, key, at);
  VitaminLogDto _pending(VitaminLogRecord row) {
    final dto = _fromRow(row);
    return row.syncStatus == 'failed'
        ? VitaminLogDto(
            id: dto.id,
            vitaminId: dto.vitaminId,
            date: dto.date,
            status: dto.status,
            syncMetadata: dto.syncMetadata.copyWith(
              syncStatus: SyncStatus.fromName(row.previousSyncStatus),
            ),
          )
        : dto;
  }

  VitaminLogDto _fromRow(VitaminLogRecord row) => VitaminLogDto(
    id: row.id,
    vitaminId: row.vitaminId,
    date: row.logDate,
    status: VitaminStatus.values.firstWhere(
      (v) => v.name == row.status,
      orElse: () => VitaminStatus.pending,
    ),
    syncMetadata: SyncMetadata(
      id: row.id,
      userId: row.userId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
      syncStatus: SyncStatus.fromName(row.syncStatus),
    ),
  );
  VitaminLogRecordsCompanion _companion(VitaminLogDto dto) =>
      VitaminLogRecordsCompanion.insert(
        id: dto.id,
        userId: userId,
        vitaminId: dto.vitaminId,
        logDate: _day(dto.date),
        status: dto.status.name,
        createdAt: dto.syncMetadata.createdAt,
        updatedAt: dto.syncMetadata.updatedAt,
        deletedAt: Value(dto.syncMetadata.deletedAt),
        syncStatus: dto.syncMetadata.syncStatus.name,
      );
  VitaminLogRecordsCompanion _copy(
    VitaminLogRecord row, {
    required SyncStatus status,
    DateTime? deletedAt,
    String? previous,
    int? attempts,
    String? error,
  }) => VitaminLogRecordsCompanion(
    id: Value(row.id),
    userId: Value(row.userId),
    vitaminId: Value(row.vitaminId),
    logDate: Value(row.logDate),
    status: Value(row.status),
    createdAt: Value(row.createdAt),
    updatedAt: Value(deletedAt ?? row.updatedAt),
    deletedAt: Value(deletedAt ?? row.deletedAt),
    syncStatus: Value(status.name),
    previousSyncStatus: Value(previous),
    syncAttempts: Value(attempts ?? row.syncAttempts),
    lastSyncError: Value(error),
  );
}
