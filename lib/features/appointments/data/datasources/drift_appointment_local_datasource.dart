import 'package:drift/drift.dart' show Value;
import '../../../../core/database/drift/app_database.dart';
import '../../../../core/database/drift/daos/appointment_dao.dart';
import '../../../../core/database/drift/migrations/appointment_legacy_service.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/sync/sync.dart';
import '../../domain/value_objects/value_objects.dart';
import '../dtos/appointment_dto.dart';

class DriftAppointmentLocalDatasource {
  const DriftAppointmentLocalDatasource({
    required AppointmentDao dao,
    required ClockService clock,
    required this.userId,
  }) : _dao = dao,
       _clock = clock;
  final AppointmentDao _dao;
  final ClockService _clock;
  final String userId;
  bool get canSync => userId != anonymousAppointmentUserId;
  Future<List<AppointmentDto>> getAll() async =>
      (await _dao.getActiveByUser(userId)).map(_fromDrift).toList();
  Future<AppointmentDto?> getById(String id) async {
    final row = await _dao.getByUserAndId(userId, id);
    return row == null ? null : _fromDrift(row);
  }

  Future<void> save(AppointmentDto value) async {
    final previous = await getById(value.id);
    final dto = AppointmentDto.fromEntity(
      value.toEntity(clock: _clock),
      now: _clock.now(),
      previousMetadata: previous?.syncMetadata.copyWith(userId: userId),
    );
    await _dao.upsert(_companion(dto));
  }

  Future<void> delete(String id) async {
    final value = await getById(id);
    if (value == null) return;
    final now = _clock.now();
    await _dao.upsert(
      _companion(
        AppointmentDto(
          id: value.id,
          title: value.title,
          date: value.date,
          status: value.status,
          doctorName: value.doctorName,
          location: value.location,
          notes: value.notes,
          syncMetadata: value.syncMetadata.copyWith(
            updatedAt: now,
            deletedAt: now,
            syncStatus: SyncStatus.pendingDelete,
          ),
        ),
      ),
    );
  }

  Future<List<AppointmentDto>> pendingSync() async => canSync
      ? (await _dao.getPendingForSync(userId)).map(_pending).toList()
      : const [];
  Future<AppointmentDto?> pendingById(String id) async {
    if (!canSync) return null;
    final row = await _dao.getByUserAndId(userId, id);
    return row == null || row.syncStatus == SyncStatus.synced.name
        ? null
        : _pending(row);
  }

  Future<void> applyRemote(AppointmentDto remote) async {
    if (!canSync || remote.syncMetadata.userId != userId) return;
    final local = await getById(remote.id);
    if (local != null &&
        !remote.syncMetadata.updatedAt.isAfter(local.syncMetadata.updatedAt)) {
      return;
    }
    await _dao.upsert(_companion(remote));
  }

  Future<void> applyRemoteAndMarkSynced(AppointmentDto remote) =>
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
  AppointmentDto _pending(AppointmentRecord row) {
    final dto = _fromDrift(row);
    return row.syncStatus == SyncStatus.failed.name
        ? AppointmentDto(
            id: dto.id,
            title: dto.title,
            date: dto.date,
            status: dto.status,
            doctorName: dto.doctorName,
            location: dto.location,
            notes: dto.notes,
            syncMetadata: dto.syncMetadata.copyWith(
              syncStatus: SyncStatus.fromName(row.previousSyncStatus),
            ),
          )
        : dto;
  }

  AppointmentDto _fromDrift(AppointmentRecord row) => AppointmentDto(
    id: row.id,
    title: row.title,
    date: row.appointmentAt,
    status: AppointmentStatus.values.firstWhere(
      (v) => v.name == row.status,
      orElse: () => AppointmentStatus.scheduled,
    ),
    doctorName: row.doctorName,
    location: row.location,
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
  AppointmentRecordsCompanion _companion(AppointmentDto dto) =>
      AppointmentRecordsCompanion.insert(
        id: dto.id,
        userId: userId,
        title: dto.title,
        appointmentAt: dto.date,
        doctorName: Value(dto.doctorName),
        location: Value(dto.location),
        notes: Value(dto.notes),
        status: dto.status.name,
        createdAt: dto.syncMetadata.createdAt,
        updatedAt: dto.syncMetadata.updatedAt,
        deletedAt: Value(dto.syncMetadata.deletedAt),
        syncStatus: dto.syncMetadata.syncStatus.name,
      );
  AppointmentRecordsCompanion _syncCopy(
    AppointmentRecord row,
    SyncStatus status,
    int attempts, {
    String? previous,
    String? error,
  }) => AppointmentRecordsCompanion(
    id: Value(row.id),
    userId: Value(row.userId),
    title: Value(row.title),
    appointmentAt: Value(row.appointmentAt),
    doctorName: Value(row.doctorName),
    location: Value(row.location),
    notes: Value(row.notes),
    status: Value(row.status),
    createdAt: Value(row.createdAt),
    updatedAt: Value(row.updatedAt),
    deletedAt: Value(row.deletedAt),
    syncStatus: Value(status.name),
    previousSyncStatus: Value(previous),
    syncAttempts: Value(attempts),
    lastSyncError: Value(error),
  );
}
