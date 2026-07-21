import 'package:drift/drift.dart';

import '../../../../core/database/drift/app_database.dart';
import '../../../../core/database/drift/daos/onboarding_state_dao.dart';
import '../../../../core/sync/sync.dart';
import '../dtos/onboarding_progress_dto.dart';

final class DriftOnboardingProgressDatasource {
  const DriftOnboardingProgressDatasource({
    required OnboardingStateDao dao,
    required this.userId,
  }) : _dao = dao;

  final OnboardingStateDao _dao;
  final String userId;

  Future<OnboardingProgressDto?> get() async {
    final row = await _dao.getByUser(userId);
    return row == null ? null : OnboardingProgressDto.fromDrift(row);
  }

  Future<void> save(OnboardingProgressDto dto) async {
    if (dto.progress.userId != userId || userId == 'anonymous') {
      throw StateError('Onboarding progress belongs to another user.');
    }
    await _dao.upsert(dto.toDrift());
  }

  Future<List<OnboardingProgressDto>> pending() async =>
      (await _dao.getPending(userId)).map(_pendingDto).toList();

  Future<OnboardingProgressDto?> pendingById(String id) async {
    final row = await _dao.getByUser(userId);
    if (row == null || row.id != id || row.syncStatus == SyncStatus.synced.name) {
      return null;
    }
    return _pendingDto(row);
  }

  Future<bool> applyRemote(OnboardingProgressDto remote) async {
    if (remote.progress.userId != userId || userId == 'anonymous') return false;
    final local = await _dao.getByUser(userId);
    if (local != null &&
        !remote.syncMetadata.updatedAt.isAfter(local.updatedAt)) {
      return false;
    }
    await _dao.upsert(remote.toDrift());
    return true;
  }

  Future<bool> applyRemoteAndMarkSynced(OnboardingProgressDto remote) =>
      _dao.inTransaction(() async {
        final applied = await applyRemote(remote);
        if (applied) await markSynced(remote.progress.id);
        return applied;
      });

  Future<void> markSynced(String id) async {
    final row = await _dao.getByUser(userId);
    if (row == null || row.id != id) return;
    await _dao.upsert(
      _copy(
        row,
        syncStatus: const Value('synced'),
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
        syncStatus: const Value('failed'),
        previousSyncStatus: Value(row.previousSyncStatus ?? row.syncStatus),
        syncAttempts: Value(row.syncAttempts + 1),
        lastSyncError: Value(error),
      ),
    );
  }

  Future<DateTime?> getLastPullAt() => _dao.getLastPullAt(userId);
  Future<void> saveCursor(DateTime at) => _dao.saveCursor(userId, at);

  OnboardingProgressDto _pendingDto(OnboardingStateRecord row) {
    final dto = OnboardingProgressDto.fromDrift(row);
    if (row.syncStatus != SyncStatus.failed.name) return dto;
    return OnboardingProgressDto(
      progress: dto.progress,
      syncMetadata: dto.syncMetadata.copyWith(
        syncStatus: SyncStatus.fromName(row.previousSyncStatus),
      ),
    );
  }

  OnboardingStateRecordsCompanion _copy(
    OnboardingStateRecord row, {
    Value<String> syncStatus = const Value.absent(),
    Value<String?> previousSyncStatus = const Value.absent(),
    Value<int> syncAttempts = const Value.absent(),
    Value<String?> lastSyncError = const Value.absent(),
  }) => OnboardingStateRecordsCompanion(
    id: Value(row.id),
    userId: Value(row.userId),
    onboardingVersion: Value(row.onboardingVersion),
    status: Value(row.status),
    currentStepId: Value(row.currentStepId),
    completedStepIdsJson: Value(row.completedStepIdsJson),
    startedAt: Value(row.startedAt),
    completedAt: Value(row.completedAt),
    createdAt: Value(row.createdAt),
    updatedAt: Value(row.updatedAt),
    deletedAt: Value(row.deletedAt),
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
