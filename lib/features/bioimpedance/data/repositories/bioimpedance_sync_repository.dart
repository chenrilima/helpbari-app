import '../../../../core/sync/sync.dart';
import '../datasources/bioimpedance_supabase_datasource.dart';
import '../datasources/drift_bioimpedance_local_datasource.dart';
import '../dtos/bioimpedance_record_dto.dart';

class BioimpedanceSyncRepository
    implements
        SyncableRepository,
        PagedPullSyncRepository,
        RepositorySyncCursor,
        AtomicRemoteSyncRepository {
  const BioimpedanceSyncRepository({
    required Future<DriftBioimpedanceLocalDatasource> Function() local,
    required BioimpedanceSupabaseDatasource remote,
    required String userId,
  }) : _local = local,
       _remote = remote,
       _userId = userId;

  static const key = 'bioimpedance';
  final Future<DriftBioimpedanceLocalDatasource> Function() _local;
  final BioimpedanceSupabaseDatasource _remote;
  final String _userId;

  @override
  String get syncKey => key;

  @override
  Future<List<SyncOperation>> pendingOperations() async =>
      (await (await _local()).pendingSync()).map(_op).toList();

  @override
  Future<SyncOperation?> localOperationById(String recordId) async {
    final dto = await (await _local()).pendingById(recordId);
    return dto == null ? null : _op(dto);
  }

  @override
  Future<void> push(SyncOperation operation) async {
    final remote = await _remote.upsert(_dto(operation), userId: _userId);
    await (await _local()).applyRemote(remote);
  }

  @override
  Future<List<SyncOperation>> pull({DateTime? updatedAfter}) async =>
      (await _remote.pull(
        userId: _userId,
        updatedAfter: updatedAfter,
      )).map(_op).toList();

  @override
  Stream<List<SyncOperation>> pullPages({
    DateTime? updatedAfter,
    int pageSize = 500,
  }) => _remote
      .pullPages(
        userId: _userId,
        updatedAfter: updatedAfter,
        pageSize: pageSize,
      )
      .map((records) => records.map(_op).toList(growable: false));

  @override
  Future<void> applyRemote(SyncOperation operation) async =>
      (await _local()).applyRemote(_dto(operation));

  @override
  Future<void> applyRemoteAndMarkSynced(
    SyncOperation operation, {
    required DateTime syncedAt,
  }) async => (await _local()).applyRemoteAndMarkSynced(_dto(operation));

  @override
  Future<void> markSynced(
    String recordId, {
    required DateTime syncedAt,
  }) async => (await _local()).markSynced(recordId);

  @override
  Future<void> markFailed(String recordId, SyncError error) async =>
      (await _local()).markFailed(recordId, error.message);

  @override
  Future<DateTime?> getLastPullAt() async =>
      (await _local()).getLastPullAt(key);

  @override
  Future<void> saveSuccessfulSync(DateTime completedAt) async =>
      (await _local()).saveCursor(key, completedAt);

  SyncOperation _op(BioimpedanceRecordDto dto) => SyncOperation(
    repositoryKey: key,
    recordId: dto.record.id,
    type: dto.syncMetadata.isDeleted
        ? SyncOperationType.delete
        : const SyncStatusMapper().operationTypeFromStatus(
            dto.syncMetadata.syncStatus,
          ),
    updatedAt: dto.syncMetadata.updatedAt,
    deletedAt: dto.syncMetadata.deletedAt,
    userId: dto.syncMetadata.userId ?? _userId,
    payload: dto.toSupabaseRow(userId: _userId),
  );

  BioimpedanceRecordDto _dto(SyncOperation operation) =>
      BioimpedanceRecordDto.fromSupabaseRow({
        ...operation.payload,
        'id': operation.recordId,
        'user_id': operation.userId ?? _userId,
        'updated_at': operation.updatedAt.toIso8601String(),
        'deleted_at': operation.deletedAt?.toIso8601String(),
      });
}
