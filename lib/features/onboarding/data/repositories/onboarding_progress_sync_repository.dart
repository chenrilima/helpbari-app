import '../../../../core/sync/sync.dart';
import '../datasources/drift_onboarding_progress_datasource.dart';
import '../datasources/onboarding_progress_supabase_datasource.dart';
import '../dtos/onboarding_progress_dto.dart';

final class OnboardingProgressSyncRepository
    implements
        SyncableRepository,
        RepositorySyncCursor,
        AtomicRemoteSyncRepository {
  const OnboardingProgressSyncRepository({
    required this.local,
    required this.remote,
    required this.userId,
  });

  static const key = 'onboarding_states';
  final Future<DriftOnboardingProgressDatasource> Function() local;
  final OnboardingProgressRemoteDatasource remote;
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
    final result = await remote.upsert(_dto(operation));
    await (await local()).applyRemote(result);
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

  SyncOperation _operation(OnboardingProgressDto dto) => SyncOperation(
    repositoryKey: key,
    recordId: dto.progress.id,
    type: dto.syncMetadata.deletedAt != null
        ? SyncOperationType.delete
        : dto.syncMetadata.syncStatus == SyncStatus.pendingCreate
        ? SyncOperationType.create
        : SyncOperationType.update,
    updatedAt: dto.syncMetadata.updatedAt,
    deletedAt: dto.syncMetadata.deletedAt,
    userId: userId,
    serverRevision: dto.syncMetadata.serverRevision,
    payload: dto.toSupabase(),
  );

  OnboardingProgressDto _dto(SyncOperation operation) =>
      OnboardingProgressDto.fromSupabase({
        ...operation.payload,
        'id': operation.recordId,
        'user_id': userId,
        'updated_at': operation.updatedAt.toUtc().toIso8601String(),
        'created_at':
            operation.payload['created_at'] ??
            operation.updatedAt.toUtc().toIso8601String(),
        'deleted_at': operation.deletedAt?.toUtc().toIso8601String(),
      });
}
