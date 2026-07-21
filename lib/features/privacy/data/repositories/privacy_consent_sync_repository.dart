import '../../../../core/sync/sync.dart';
import '../datasources/drift_privacy_consent_datasource.dart';
import '../datasources/privacy_supabase_datasource.dart';
import '../dtos/privacy_consent_dto.dart';

class PrivacyConsentSyncRepository
    implements
        SyncableRepository,
        RepositorySyncCursor,
        AtomicRemoteSyncRepository {
  const PrivacyConsentSyncRepository({
    required this.local,
    required this.remote,
    required this.userId,
  });

  static const key = 'privacy_consents';
  final Future<DriftPrivacyConsentDatasource> Function() local;
  final PrivacyRemoteDatasource remote;
  final String userId;

  @override
  String get syncKey => key;

  @override
  Future<List<SyncOperation>> pendingOperations() async =>
      (await (await local()).pending()).map(_operation).toList();

  @override
  Future<SyncOperation?> localOperationById(String recordId) async {
    final dto = await (await local()).pendingById(recordId);
    return dto == null ? null : _operation(dto);
  }

  @override
  Future<void> push(SyncOperation operation) async {
    final remoteDto = await remote.upsert(_dto(operation));
    await (await local()).applyRemote(remoteDto);
  }

  @override
  Future<List<SyncOperation>> pull({DateTime? updatedAfter}) async =>
      (await remote.pull(userId, updatedAfter)).map(_operation).toList();

  @override
  Future<void> applyRemote(SyncOperation operation) async =>
      (await local()).applyRemote(_dto(operation));

  @override
  Future<void> applyRemoteAndMarkSynced(
    SyncOperation operation, {
    required DateTime syncedAt,
  }) async => (await local()).applyRemoteAndMarkSynced(_dto(operation));

  @override
  Future<void> markSynced(String recordId, {required DateTime syncedAt}) =>
      local().then((value) => value.markSynced(recordId));

  @override
  Future<void> markFailed(String recordId, SyncError error) =>
      local().then((value) => value.markFailed(recordId, error.message));

  @override
  Future<DateTime?> getLastPullAt() =>
      local().then((value) => value.getLastPullAt());

  @override
  Future<void> saveSuccessfulSync(DateTime completedAt) =>
      local().then((value) => value.saveCursor(completedAt));

  SyncOperation _operation(PrivacyConsentDto dto) => SyncOperation(
    repositoryKey: key,
    recordId: dto.consent.id,
    type: SyncOperationType.create,
    updatedAt: dto.syncMetadata.updatedAt,
    userId: userId,
    serverRevision: dto.syncMetadata.serverRevision,
    payload: dto.toSupabase(),
  );

  PrivacyConsentDto _dto(SyncOperation operation) =>
      PrivacyConsentDto.fromSupabase({
        ...operation.payload,
        'id': operation.recordId,
        'user_id': userId,
        'updated_at': operation.updatedAt.toIso8601String(),
        'created_at':
            operation.payload['created_at'] ??
            operation.updatedAt.toIso8601String(),
      });
}
