import 'package:drift/drift.dart' show Value;

import '../../../../core/database/drift/app_database.dart';
import '../../../../core/database/drift/daos/settings_dao.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/sync/sync.dart';
import '../dtos/settings_dto.dart';
import '../../domain/entities/entities.dart';

class DriftSettingsLocalDatasource {
  const DriftSettingsLocalDatasource({
    required SettingsDao dao,
    required ClockService clock,
    required this.userId,
  }) : _dao = dao,
       _clock = clock;
  final SettingsDao _dao;
  final ClockService _clock;
  final String userId;

  Future<SettingsDto> getSettings() async {
    final row = await _dao.getByUser(userId);
    if (row != null) return SettingsDto.fromDrift(row);
    final now = _clock.now();
    final dto = SettingsDto.fromEntity(
      AppSettings(id: userId),
      now: now,
      userId: userId,
    );
    await _dao.upsert(dto.toDrift(userId: userId));
    return dto;
  }

  Future<void> save(SettingsDto input) async {
    final previous = await _dao.getByUser(userId);
    final dto = SettingsDto.fromEntity(
      input.toEntity(),
      now: _clock.now(),
      userId: userId,
      previousMetadata: previous == null
          ? null
          : SettingsDto.fromDrift(previous).syncMetadata,
    );
    await _dao.upsert(dto.toDrift(userId: userId));
  }

  Future<List<SettingsDto>> pending() async {
    if (userId == 'anonymous') return const [];
    return (await _dao.getPending(userId)).map(_pendingDto).toList();
  }

  Future<SettingsDto?> pendingById(String id) async {
    if (userId == 'anonymous') return null;
    final row = await _dao.getByUser(userId);
    if (row == null ||
        row.id != id ||
        row.syncStatus == SyncStatus.synced.name) {
      return null;
    }
    return _pendingDto(row);
  }

  Future<void> softDelete() async {
    final row = await _dao.getByUser(userId);
    if (row == null) return;
    final now = _clock.now();
    await _dao.upsert(
      _copy(
        row,
        deletedAt: Value(now),
        syncStatus: Value(SyncStatus.pendingDelete.name),
        updatedAt: Value(now),
      ),
    );
  }

  Future<bool> applyRemote(SettingsDto remote) async {
    if (userId == 'anonymous' || remote.syncMetadata.userId != userId) {
      return false;
    }
    final local = await _dao.getByUser(userId);
    if (local != null &&
        !remote.syncMetadata.updatedAt.isAfter(local.updatedAt)) {
      return false;
    }
    await _dao.upsert(remote.toDrift(userId: userId));
    return true;
  }

  Future<bool> applyRemoteAndMarkSynced(SettingsDto remote) =>
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

  SettingsDto _pendingDto(SettingsRecord row) {
    final dto = SettingsDto.fromDrift(row);
    if (row.syncStatus != SyncStatus.failed.name) return dto;
    return SettingsDto(
      id: dto.id,
      dailyWaterGoalMl: dto.dailyWaterGoalMl,
      vitaminRemindersEnabled: dto.vitaminRemindersEnabled,
      medicationRemindersEnabled: dto.medicationRemindersEnabled,
      appointmentRemindersEnabled: dto.appointmentRemindersEnabled,
      mealTrackingEnabled: dto.mealTrackingEnabled,
      treatmentTrackingEnabled: dto.treatmentTrackingEnabled,
      waterTrackingEnabled: dto.waterTrackingEnabled,
      weightTrackingEnabled: dto.weightTrackingEnabled,
      weightUnit: dto.weightUnit,
      notificationPreferencesJson: dto.notificationPreferencesJson,
      syncMetadata: dto.syncMetadata.copyWith(
        syncStatus: SyncStatus.fromName(row.previousSyncStatus),
      ),
    );
  }

  SettingsRecordsCompanion _copy(
    SettingsRecord row, {
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<DateTime> updatedAt = const Value.absent(),
    Value<String> syncStatus = const Value.absent(),
    Value<String?> previousSyncStatus = const Value.absent(),
    Value<int> syncAttempts = const Value.absent(),
    Value<String?> lastSyncError = const Value.absent(),
  }) => SettingsRecordsCompanion(
    id: Value(row.id),
    userId: Value(row.userId),
    dailyWaterGoalMl: Value(row.dailyWaterGoalMl),
    vitaminRemindersEnabled: Value(row.vitaminRemindersEnabled),
    medicationRemindersEnabled: Value(row.medicationRemindersEnabled),
    appointmentRemindersEnabled: Value(row.appointmentRemindersEnabled),
    mealTrackingEnabled: Value(row.mealTrackingEnabled),
    treatmentTrackingEnabled: Value(row.treatmentTrackingEnabled),
    waterTrackingEnabled: Value(row.waterTrackingEnabled),
    weightTrackingEnabled: Value(row.weightTrackingEnabled),
    weightUnit: Value(row.weightUnit),
    notificationPreferencesJson: Value(row.notificationPreferencesJson),
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
