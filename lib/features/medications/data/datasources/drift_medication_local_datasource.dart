import 'package:drift/drift.dart' show Value;
import '../../../../core/database/drift/app_database.dart';
import '../../../../core/database/drift/daos/medication_dao.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/sync/sync.dart';
import '../dtos/medication_dto.dart';

class DriftMedicationLocalDatasource {
  const DriftMedicationLocalDatasource({
    required MedicationDao dao,
    required ClockService clock,
    required this.userId,
  }) : _dao = dao,
       _clock = clock;
  final MedicationDao _dao;
  final ClockService _clock;
  final String userId;
  bool get canSync => userId != 'anonymous';
  Future<List<MedicationDto>> getAll() async =>
      (await _dao.getActiveByUser(userId)).map(_fromRow).toList();
  Future<MedicationDto?> getById(String id) async {
    final row = await _dao.getByUserAndId(userId, id);
    return row == null ? null : _fromRow(row);
  }

  Future<void> save(MedicationDto value) async {
    final old = await getById(value.id);
    final dto = MedicationDto.fromEntity(
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
        MedicationDto(
          id: old.id,
          name: old.name,
          hour: old.hour,
          minute: old.minute,
          dosage: old.dosage,
          notes: old.notes,
          syncMetadata: old.syncMetadata.copyWith(
            updatedAt: now,
            deletedAt: now,
            syncStatus: SyncStatus.pendingDelete,
          ),
        ),
      ),
    );
  }

  Future<List<MedicationDto>> pendingSync() async => canSync
      ? (await _dao.getPendingForSync(userId)).map(_pending).toList()
      : const [];
  Future<MedicationDto?> pendingById(String id) async {
    if (!canSync) return null;
    final row = await _dao.getByUserAndId(userId, id);
    return row == null || row.syncStatus == 'synced' ? null : _pending(row);
  }

  Future<void> applyRemote(MedicationDto remote) async {
    if (!canSync || remote.syncMetadata.userId != userId) return;
    final local = await getById(remote.id);
    if (local != null &&
        !remote.syncMetadata.updatedAt.isAfter(local.syncMetadata.updatedAt)) {
      return;
    }
    await _dao.upsert(_companion(remote));
  }

  Future<void> applyRemoteAndMarkSynced(MedicationDto remote) =>
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
  MedicationDto _pending(MedicationRecord r) {
    final d = _fromRow(r);
    return r.syncStatus == 'failed'
        ? MedicationDto(
            id: d.id,
            name: d.name,
            hour: d.hour,
            minute: d.minute,
            dosage: d.dosage,
            notes: d.notes,
            syncMetadata: d.syncMetadata.copyWith(
              syncStatus: SyncStatus.fromName(r.previousSyncStatus),
            ),
          )
        : d;
  }

  MedicationDto _fromRow(MedicationRecord r) => MedicationDto(
    id: r.id,
    name: r.name,
    hour: r.scheduleHour,
    minute: r.scheduleMinute,
    dosage: r.dosage,
    notes: r.notes,
    syncMetadata: SyncMetadata(
      id: r.id,
      userId: r.userId,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
      deletedAt: r.deletedAt,
      syncStatus: SyncStatus.fromName(r.syncStatus),
    ),
  );
  MedicationRecordsCompanion _companion(MedicationDto d) =>
      MedicationRecordsCompanion.insert(
        id: d.id,
        userId: userId,
        name: d.name,
        scheduleHour: d.hour,
        scheduleMinute: d.minute,
        dosage: Value(d.dosage),
        notes: Value(d.notes),
        createdAt: d.syncMetadata.createdAt,
        updatedAt: d.syncMetadata.updatedAt,
        deletedAt: Value(d.syncMetadata.deletedAt),
        syncStatus: d.syncMetadata.syncStatus.name,
      );
  MedicationRecordsCompanion _syncCopy(
    MedicationRecord r,
    SyncStatus status,
    int attempts, {
    String? previous,
    String? error,
  }) => MedicationRecordsCompanion(
    id: Value(r.id),
    userId: Value(r.userId),
    name: Value(r.name),
    scheduleHour: Value(r.scheduleHour),
    scheduleMinute: Value(r.scheduleMinute),
    dosage: Value(r.dosage),
    notes: Value(r.notes),
    createdAt: Value(r.createdAt),
    updatedAt: Value(r.updatedAt),
    deletedAt: Value(r.deletedAt),
    syncStatus: Value(status.name),
    previousSyncStatus: Value(previous),
    syncAttempts: Value(attempts),
    lastSyncError: Value(error),
  );
}
