import '../../../../core/sync/sync.dart';
import '../datasources/drift_profile_local_datasource.dart';
import '../datasources/profile_supabase_datasource.dart';
import '../dtos/profile_dto.dart';

class ProfileSyncRepository
    implements
        SyncableRepository,
        RepositorySyncCursor,
        AtomicRemoteSyncRepository {
  const ProfileSyncRepository({
    required this.local,
    required this.remote,
    required this.userId,
  });
  static const key = 'profile';
  final Future<DriftProfileLocalDatasource> Function() local;
  final ProfileRemoteDatasource remote;
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
    await remote.upsert(_dto(operation), userId);
  }

  @override
  Future<List<SyncOperation>> pull({DateTime? updatedAfter}) async =>
      (await remote.pull(userId, updatedAfter)).map(_operation).toList();
  @override
  Future<void> applyRemote(SyncOperation operation) async {
    await (await local()).applyRemote(_dto(operation));
  }

  @override
  Future<void> applyRemoteAndMarkSynced(
    SyncOperation operation, {
    required DateTime syncedAt,
  }) async {
    await (await local()).applyRemoteAndMarkSynced(_dto(operation));
  }

  @override
  Future<void> markSynced(
    String recordId, {
    required DateTime syncedAt,
  }) async => (await local()).markSynced(recordId);
  @override
  Future<void> markFailed(String recordId, SyncError error) async =>
      (await local()).markFailed(recordId, error.message);
  @override
  Future<DateTime?> getLastPullAt() async => (await local()).getLastPullAt();
  @override
  Future<void> saveSuccessfulSync(DateTime completedAt) async =>
      (await local()).saveCursor(completedAt);

  SyncOperation _operation(ProfileDto dto) => SyncOperation(
    repositoryKey: key,
    recordId: dto.id,
    type: dto.syncMetadata.deletedAt != null
        ? SyncOperationType.delete
        : dto.syncMetadata.syncStatus == SyncStatus.pendingCreate
        ? SyncOperationType.create
        : SyncOperationType.update,
    updatedAt: dto.syncMetadata.updatedAt,
    deletedAt: dto.syncMetadata.deletedAt,
    userId: userId,
    payload: dto.toSupabase(userId),
  );
  ProfileDto _dto(SyncOperation operation) => ProfileDto.fromSupabase({
    ...operation.payload,
    'user_id': userId,
    'updated_at': operation.updatedAt.toIso8601String(),
    'deleted_at': operation.deletedAt?.toIso8601String(),
  });
}
