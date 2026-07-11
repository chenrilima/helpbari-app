import 'package:drift/drift.dart' show Value;

import '../../../../core/database/drift/app_database.dart';
import '../../../../core/database/drift/daos/profile_dao.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/sync/sync.dart';
import '../../domain/entities/entities.dart';
import '../dtos/profile_dto.dart';

class DriftProfileLocalDatasource {
  const DriftProfileLocalDatasource({
    required ProfileDao dao,
    required ClockService clock,
    required this.userId,
  }) : _dao = dao,
       _clock = clock;

  final ProfileDao _dao;
  final ClockService _clock;
  final String userId;

  Future<ProfileDto?> getProfile() async {
    final row = await _dao.getByUser(userId);
    if (row == null || row.deletedAt != null) return null;
    return ProfileDto.fromDrift(row);
  }

  Future<void> save(Profile input) async {
    final previous = await _dao.getByUser(userId);
    final dto = ProfileDto.fromEntity(
      input,
      now: _clock.now(),
      userId: userId,
      previousMetadata: previous == null
          ? null
          : ProfileDto.fromDrift(previous).syncMetadata,
    );
    await _dao.upsert(dto.toDrift(userId: userId));
  }

  Future<void> softDelete(String id) async {
    final row = await _dao.getByUser(userId);
    if (row == null || row.id != id) return;
    final now = _clock.now();
    await _dao.upsert(
      _copy(
        row,
        deletedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: Value(SyncStatus.pendingDelete.name),
      ),
    );
  }

  Future<List<ProfileDto>> pending() async =>
      (await _dao.getPending(userId)).map(_pendingDto).toList();

  Future<ProfileDto?> pendingById(String id) async {
    final row = await _dao.getByUser(userId);
    if (row == null || row.id != id || row.syncStatus == 'synced') return null;
    return _pendingDto(row);
  }

  Future<bool> applyRemote(ProfileDto remote) async {
    if (remote.syncMetadata.userId != userId) return false;
    final local = await _dao.getByUser(userId);
    if (local != null &&
        !remote.syncMetadata.updatedAt.isAfter(local.updatedAt)) {
      return false;
    }
    await _dao.upsert(remote.toDrift(userId: userId));
    return true;
  }

  Future<bool> applyRemoteAndMarkSynced(ProfileDto remote) =>
      _dao.inTransaction(() async {
        final applied = await applyRemote(remote);
        if (applied) await markSynced(remote.id);
        return applied;
      });

  Future<void> markSynced(String id) async {
    final row = await _dao.getByUser(userId);
    if (row == null || row.id != id) return;
    await _dao.upsert(
      _copy(
        row,
        syncStatus: Value(SyncStatus.synced.name),
        previousSyncStatus: const Value(null),
        syncAttempts: const Value(0),
        lastSyncError: const Value(null),
      ),
    );
  }

  Future<void> markFailed(String id, String error) async {
    final row = await _dao.getByUser(userId);
    if (row == null || row.id != id) return;
    await _dao.upsert(
      _copy(
        row,
        syncStatus: Value(SyncStatus.failed.name),
        previousSyncStatus: Value(row.previousSyncStatus ?? row.syncStatus),
        syncAttempts: Value(row.syncAttempts + 1),
        lastSyncError: Value(error),
      ),
    );
  }

  Future<DateTime?> getLastPullAt() => _dao.getLastPullAt(userId);
  Future<void> saveCursor(DateTime at) => _dao.saveCursor(userId, at);

  ProfileDto _pendingDto(ProfileRecord row) {
    final dto = ProfileDto.fromDrift(row);
    if (row.syncStatus != SyncStatus.failed.name) return dto;
    return _withMetadata(
      dto,
      dto.syncMetadata.copyWith(
        syncStatus: SyncStatus.fromName(row.previousSyncStatus),
      ),
    );
  }

  ProfileDto _withMetadata(ProfileDto dto, SyncMetadata metadata) => ProfileDto(
    id: dto.id,
    name: dto.name,
    email: dto.email,
    createdAt: dto.createdAt,
    birthDate: dto.birthDate,
    heightInCentimeters: dto.heightInCentimeters,
    initialWeight: dto.initialWeight,
    targetWeight: dto.targetWeight,
    surgeryDate: dto.surgeryDate,
    surgeryType: dto.surgeryType,
    photoUrl: dto.photoUrl,
    syncMetadata: metadata,
  );

  ProfileRecordsCompanion _copy(
    ProfileRecord row, {
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<DateTime> updatedAt = const Value.absent(),
    Value<String> syncStatus = const Value.absent(),
    Value<String?> previousSyncStatus = const Value.absent(),
    Value<int> syncAttempts = const Value.absent(),
    Value<String?> lastSyncError = const Value.absent(),
  }) => ProfileRecordsCompanion(
    id: Value(row.id),
    userId: Value(row.userId),
    name: Value(row.name),
    email: Value(row.email),
    birthDate: Value(row.birthDate),
    heightInCentimeters: Value(row.heightInCentimeters),
    initialWeight: Value(row.initialWeight),
    targetWeight: Value(row.targetWeight),
    surgeryDate: Value(row.surgeryDate),
    surgeryType: Value(row.surgeryType),
    photoUrl: Value(row.photoUrl),
    createdAt: Value(row.createdAt),
    updatedAt: updatedAt.present ? updatedAt : Value(row.updatedAt),
    deletedAt: deletedAt.present ? deletedAt : Value(row.deletedAt),
    syncStatus: syncStatus.present ? syncStatus : Value(row.syncStatus),
    previousSyncStatus: previousSyncStatus.present
        ? previousSyncStatus
        : Value(row.previousSyncStatus),
    syncAttempts: syncAttempts.present ? syncAttempts : Value(row.syncAttempts),
    lastSyncError: lastSyncError.present
        ? lastSyncError
        : Value(row.lastSyncError),
  );
}
