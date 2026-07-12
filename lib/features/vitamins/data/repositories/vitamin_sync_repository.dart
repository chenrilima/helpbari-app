import '../../../../core/sync/sync.dart';
import '../datasources/drift_vitamin_local_datasource.dart';
import '../datasources/vitamin_supabase_datasource.dart';
import '../dtos/vitamin_dto.dart';

class VitaminSyncRepository
    implements
        SyncableRepository,
        RepositorySyncCursor,
        AtomicRemoteSyncRepository {
  const VitaminSyncRepository({
    required Future<DriftVitaminLocalDatasource> Function() local,
    required VitaminSupabaseDatasource remote,
    required String userId,
    this.afterRemoteCommit,
  }) : _local = local,
       _remote = remote,
       _userId = userId;
  static const key = 'vitamins';
  final Future<DriftVitaminLocalDatasource> Function() _local;
  final VitaminSupabaseDatasource _remote;
  final String _userId;
  final Future<void> Function(VitaminDto)? afterRemoteCommit;
  @override
  String get syncKey => key;
  @override
  Future<List<SyncOperation>> pendingOperations() async =>
      (await (await _local()).pendingSync()).map(_op).toList();
  @override
  Future<SyncOperation?> localOperationById(String id) async {
    final dto = await (await _local()).pendingById(id);
    return dto == null ? null : _op(dto);
  }

  @override
  Future<void> push(SyncOperation operation) async => (await _local())
      .applyRemote(await _remote.upsert(_dto(operation), userId: _userId));
  @override
  Future<List<SyncOperation>> pull({DateTime? updatedAfter}) async =>
      (await _remote.pull(
        userId: _userId,
        updatedAfter: updatedAfter,
      )).map(_op).toList();
  @override
  Future<void> applyRemote(SyncOperation operation) async =>
      (await _local()).applyRemote(_dto(operation));
  @override
  Future<void> applyRemoteAndMarkSynced(
    SyncOperation operation, {
    required DateTime syncedAt,
  }) async {
    final dto = _dto(operation);
    await (await _local()).applyRemoteAndMarkSynced(dto);
    await afterRemoteCommit?.call(dto);
  }

  @override
  Future<void> markSynced(String id, {required DateTime syncedAt}) async =>
      (await _local()).markSynced(id);
  @override
  Future<void> markFailed(String id, SyncError error) async =>
      (await _local()).markFailed(id, error.message);
  @override
  Future<DateTime?> getLastPullAt() async =>
      (await _local()).getLastPullAt(key);
  @override
  Future<void> saveSuccessfulSync(DateTime at) async =>
      (await _local()).saveCursor(key, at);
  SyncOperation _op(VitaminDto d) => SyncOperation(
    repositoryKey: key,
    recordId: d.id,
    type: d.syncMetadata.isDeleted
        ? SyncOperationType.delete
        : const SyncStatusMapper().operationTypeFromStatus(
            d.syncMetadata.syncStatus,
          ),
    updatedAt: d.syncMetadata.updatedAt,
    deletedAt: d.syncMetadata.deletedAt,
    userId: d.syncMetadata.userId ?? _userId,
    payload: {
      'name': d.name,
      'hour': d.hour,
      'minute': d.minute,
      'createdAt': d.syncMetadata.createdAt.toIso8601String(),
    },
  );
  VitaminDto _dto(SyncOperation o) => VitaminDto(
    id: o.recordId,
    name: o.payload['name'] as String,
    hour: o.payload['hour'] as int,
    minute: o.payload['minute'] as int,
    syncMetadata: SyncMetadata(
      id: o.recordId,
      userId: o.userId ?? _userId,
      createdAt: DateTime.parse(o.payload['createdAt'] as String),
      updatedAt: o.updatedAt,
      deletedAt: o.deletedAt,
      syncStatus: o.syncStatus,
    ),
  );
}
