import 'package:drift/drift.dart' show Value;
import '../../../../core/database/drift/app_database.dart';
import '../../../../core/database/drift/daos/medication_log_dao.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/services/uuid_service.dart';
import '../../../../core/sync/sync.dart';
import '../../domain/value_objects/medication_status.dart';
import '../dtos/medication_log_dto.dart';

class DriftMedicationLogLocalDatasource {
  const DriftMedicationLogLocalDatasource({
    required MedicationLogDao dao,
    required ClockService clock,
    required UuidService uuid,
    required this.userId,
  }) : _dao = dao,
       _clock = clock,
       _uuid = uuid;
  final MedicationLogDao _dao;
  final ClockService _clock;
  final UuidService _uuid;
  final String userId;
  bool get canSync => userId != 'anonymous';
  DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
  Future<List<MedicationLogDto>> getByPeriod(
    DateTime start,
    DateTime end,
  ) async => (await _dao.getByPeriod(
    userId,
    _day(start),
    _day(end),
  )).map(_fromRow).toList();
  Future<MedicationLogDto> setStatus({
    required String medicationId,
    required DateTime date,
    required MedicationStatus status,
  }) async {
    final day = _day(date);
    final row = await _dao.getByMedicationAndDate(userId, medicationId, day);
    final now = _clock.now();
    final id = row?.id ?? _uuid.generate();
    final dto = MedicationLogDto(
      id: id,
      medicationId: medicationId,
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

  Future<void> deleteForMedication(String medicationId) async {
    final rows = await _dao.getByPeriod(userId, DateTime(1970), DateTime(9999));
    final now = _clock.now();
    for (final row in rows.where((r) => r.medicationId == medicationId)) {
      await _dao.upsert(
        _copy(row, status: SyncStatus.pendingDelete, deletedAt: now),
      );
    }
  }

  Future<List<MedicationLogDto>> pendingSync() async => canSync
      ? (await _dao.getPendingForSync(userId)).map(_pending).toList()
      : const [];
  Future<MedicationLogDto?> pendingById(String id) async {
    if (!canSync) return null;
    final row = await _dao.getByUserAndId(userId, id);
    return row == null || row.syncStatus == 'synced' ? null : _pending(row);
  }

  Future<void> applyRemote(MedicationLogDto remote) async {
    if (!canSync || remote.syncMetadata.userId != userId) return;
    final local = await _dao.getByUserAndId(userId, remote.id);
    if (local != null &&
        !remote.syncMetadata.updatedAt.isAfter(local.updatedAt)) {
      return;
    }
    await _dao.upsert(_companion(remote));
  }

  Future<void> applyRemoteAndMarkSynced(MedicationLogDto remote) =>
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
  MedicationLogDto _pending(MedicationLogRecord r) {
    final d = _fromRow(r);
    return r.syncStatus == 'failed'
        ? MedicationLogDto(
            id: d.id,
            medicationId: d.medicationId,
            date: d.date,
            status: d.status,
            syncMetadata: d.syncMetadata.copyWith(
              syncStatus: SyncStatus.fromName(r.previousSyncStatus),
            ),
          )
        : d;
  }

  MedicationLogDto _fromRow(MedicationLogRecord r) => MedicationLogDto(
    id: r.id,
    medicationId: r.medicationId,
    date: r.logDate,
    status: MedicationStatus.values.firstWhere(
      (v) => v.name == r.status,
      orElse: () => MedicationStatus.pending,
    ),
    syncMetadata: SyncMetadata(
      id: r.id,
      userId: r.userId,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
      deletedAt: r.deletedAt,
      syncStatus: SyncStatus.fromName(r.syncStatus),
    ),
  );
  MedicationLogRecordsCompanion _companion(MedicationLogDto d) =>
      MedicationLogRecordsCompanion.insert(
        id: d.id,
        userId: userId,
        medicationId: d.medicationId,
        logDate: _day(d.date),
        status: d.status.name,
        createdAt: d.syncMetadata.createdAt,
        updatedAt: d.syncMetadata.updatedAt,
        deletedAt: Value(d.syncMetadata.deletedAt),
        syncStatus: d.syncMetadata.syncStatus.name,
      );
  MedicationLogRecordsCompanion _copy(
    MedicationLogRecord r, {
    required SyncStatus status,
    DateTime? deletedAt,
    String? previous,
    int? attempts,
    String? error,
  }) => MedicationLogRecordsCompanion(
    id: Value(r.id),
    userId: Value(r.userId),
    medicationId: Value(r.medicationId),
    logDate: Value(r.logDate),
    status: Value(r.status),
    createdAt: Value(r.createdAt),
    updatedAt: Value(deletedAt ?? r.updatedAt),
    deletedAt: Value(deletedAt ?? r.deletedAt),
    syncStatus: Value(status.name),
    previousSyncStatus: Value(previous),
    syncAttempts: Value(attempts ?? r.syncAttempts),
    lastSyncError: Value(error),
  );
}
