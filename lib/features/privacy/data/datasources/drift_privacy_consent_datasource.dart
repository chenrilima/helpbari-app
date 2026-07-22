import 'package:drift/drift.dart';

import '../../../../core/database/drift/app_database.dart';
import '../../../../core/database/drift/daos/privacy_consent_dao.dart';
import '../../../../core/sync/sync.dart';
import '../dtos/privacy_consent_dto.dart';

class DriftPrivacyConsentDatasource {
  const DriftPrivacyConsentDatasource({
    required PrivacyConsentDao dao,
    required this.userId,
  }) : _dao = dao;

  final PrivacyConsentDao _dao;
  final String userId;

  Future<List<PrivacyConsentDto>> getAll() async =>
      (await _dao.getByUser(userId)).map(PrivacyConsentDto.fromDrift).toList();

  Future<void> save(PrivacyConsentDto dto) async {
    if (dto.consent.userId != userId) {
      throw StateError('Privacy consent belongs to another user.');
    }
    await _dao.upsert(dto.toDrift());
  }

  Future<List<PrivacyConsentDto>> pending() async =>
      (await _dao.getPending(userId)).map(_pendingDto).toList();

  Future<PrivacyConsentDto?> pendingById(String id) async {
    final row = await _dao.getByUserAndId(userId, id);
    if (row == null || row.syncStatus == SyncStatus.synced.name) return null;
    return _pendingDto(row);
  }

  Future<bool> applyRemote(PrivacyConsentDto remote) async {
    if (remote.consent.userId != userId || userId == 'anonymous') return false;
    final local = await _dao.getByUserAndId(userId, remote.consent.id);
    if (local != null &&
        !remote.syncMetadata.updatedAt.isAfter(local.updatedAt)) {
      return false;
    }
    final sameVersion = await _dao.getByUserAndVersions(
      userId,
      remote.consent.termsVersion,
      remote.consent.privacyVersion,
    );
    if (sameVersion != null &&
        !remote.syncMetadata.updatedAt.isAfter(sameVersion.updatedAt)) {
      return false;
    }
    await _dao.replaceVersion(remote.toDrift());
    return true;
  }

  Future<bool> applyRemoteAndMarkSynced(PrivacyConsentDto remote) =>
      _dao.inTransaction(() async {
        final applied = await applyRemote(remote);
        if (applied) await markSynced(remote.consent.id);
        return applied;
      });

  Future<void> markSynced(String id) async {
    final row = await _dao.getByUserAndId(userId, id);
    if (row == null) return;
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
    final row = await _dao.getByUserAndId(userId, id);
    if (row == null) return;
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

  PrivacyConsentDto _pendingDto(PrivacyConsentRecord row) {
    final dto = PrivacyConsentDto.fromDrift(row);
    if (row.syncStatus != SyncStatus.failed.name) return dto;
    return PrivacyConsentDto(
      consent: dto.consent,
      syncMetadata: dto.syncMetadata.copyWith(
        syncStatus: SyncStatus.fromName(row.previousSyncStatus),
      ),
    );
  }

  PrivacyConsentRecordsCompanion _copy(
    PrivacyConsentRecord row, {
    Value<String> syncStatus = const Value.absent(),
    Value<String?> previousSyncStatus = const Value.absent(),
    Value<int> syncAttempts = const Value.absent(),
    Value<String?> lastSyncError = const Value.absent(),
  }) => PrivacyConsentRecordsCompanion(
    id: Value(row.id),
    userId: Value(row.userId),
    termsVersion: Value(row.termsVersion),
    privacyVersion: Value(row.privacyVersion),
    acceptedAt: Value(row.acceptedAt),
    deviceId: Value(row.deviceId),
    timezone: Value(row.timezone),
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
