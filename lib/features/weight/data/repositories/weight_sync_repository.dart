import '../../../../core/supabase/database/supabase_database.dart';
import '../../../../core/sync/sync.dart';
import '../datasources/drift_weight_local_datasource.dart';
import '../datasources/weight_supabase_datasource.dart';
import '../dtos/weight_record_dto.dart';

class WeightSyncRepository
    implements
        SyncableRepository,
        PagedPullSyncRepository,
        RepositorySyncCursor,
        AtomicRemoteSyncRepository,
        VersionedPushSyncRepository {
  const WeightSyncRepository({
    required Future<DriftWeightLocalDatasource> Function() local,
    required WeightSupabaseDatasource remote,
    required String userId,
    SyncStatusMapper statusMapper = const SyncStatusMapper(),
  }) : _local = local,
       _remote = remote,
       _userId = userId,
       _statusMapper = statusMapper;
  static const key = 'weight';
  final Future<DriftWeightLocalDatasource> Function() _local;
  final WeightSupabaseDatasource _remote;
  final String _userId;
  final SyncStatusMapper _statusMapper;
  @override
  String get syncKey => key;
  @override
  Future<List<SyncOperation>> pendingOperations() async =>
      (await (await _local()).pendingSync()).map(_operation).toList();
  @override
  Future<SyncOperation?> localOperationById(String id) async {
    final dto = await (await _local()).pendingById(id);
    return dto == null ? null : _operation(dto);
  }

  @override
  Future<void> push(SyncOperation operation) async {
    final dto = _dto(operation);
    // Local legacy records may already be pendingUpdate/pendingDelete even when
    // no remote row exists. Upsert keeps every push idempotent and also
    // persists tombstones without relying on the remote row being present.
    final remote = await _remote.upsert(dto, userId: _userId);
    await (await _local()).applyRemote(remote);
  }

  @override
  Future<SyncOperation> pushVersioned(
    SyncOperation operation, {
    required int? baseRevision,
  }) async {
    try {
      final remote = await _remote.upsertVersioned(
        _dto(operation),
        userId: _userId,
        baseRevision: baseRevision,
      );
      await (await _local()).applyRemote(remote);
      return _operation(remote);
    } on SupabaseRevisionConflictException catch (error) {
      throw SyncRevisionConflictException(
        _operation(WeightRecordDto.fromSupabaseRow(error.remoteRow)),
      );
    }
  }

  @override
  Future<List<SyncOperation>> pull({DateTime? updatedAfter}) async =>
      (await _remote.pull(
        userId: _userId,
        updatedAfter: updatedAfter,
      )).map(_operation).toList();
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
      .map((records) => records.map(_operation).toList(growable: false));
  @override
  Future<void> applyRemote(SyncOperation operation) async =>
      (await _local()).applyRemote(_dto(operation));
  @override
  Future<void> applyRemoteAndMarkSynced(
    SyncOperation operation, {
    required DateTime syncedAt,
  }) async => (await _local()).applyRemoteAndMarkSynced(_dto(operation));
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

  SyncOperation _operation(WeightRecordDto dto) => SyncOperation(
    repositoryKey: key,
    recordId: dto.id,
    type: dto.syncMetadata.isDeleted
        ? SyncOperationType.delete
        : _statusMapper.operationTypeFromStatus(dto.syncMetadata.syncStatus),
    updatedAt: dto.syncMetadata.updatedAt,
    deletedAt: dto.syncMetadata.deletedAt,
    userId: dto.syncMetadata.userId ?? _userId,
    serverRevision: dto.syncMetadata.serverRevision,
    payload: {
      'weight': dto.weight,
      'recordedAt': dto.recordedAt.toIso8601String(),
      'notes': dto.notes,
      'createdAt': dto.syncMetadata.createdAt.toIso8601String(),
      'updatedAt': dto.syncMetadata.updatedAt.toIso8601String(),
      'deletedAt': dto.syncMetadata.deletedAt?.toIso8601String(),
    },
  );
  WeightRecordDto _dto(SyncOperation op) => WeightRecordDto(
    id: op.recordId,
    weight: (op.payload['weight'] as num).toDouble(),
    recordedAt: DateTime.parse(op.payload['recordedAt'] as String),
    notes: op.payload['notes'] as String?,
    syncMetadata: SyncMetadata(
      id: op.recordId,
      userId: op.userId ?? _userId,
      createdAt: DateTime.parse(op.payload['createdAt'] as String),
      updatedAt: op.updatedAt,
      deletedAt: op.deletedAt,
      syncStatus: op.syncStatus,
    ),
  );
}
