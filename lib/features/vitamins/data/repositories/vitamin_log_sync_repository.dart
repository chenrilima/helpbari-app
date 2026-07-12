import '../../../../core/sync/sync.dart';
import '../../domain/value_objects/vitamin_status.dart';
import '../datasources/drift_vitamin_log_local_datasource.dart';
import '../datasources/vitamin_log_supabase_datasource.dart';
import '../dtos/vitamin_log_dto.dart';

class VitaminLogSyncRepository
    implements
        SyncableRepository,
        RepositorySyncCursor,
        AtomicRemoteSyncRepository {
  const VitaminLogSyncRepository({
    required Future<DriftVitaminLogLocalDatasource> Function() local,
    required VitaminLogSupabaseDatasource remote,
    required String userId,
  }) : _local = local,
       _remote = remote,
       _userId = userId;
  static const key = 'vitamin_logs';
  final Future<DriftVitaminLogLocalDatasource> Function() _local;
  final VitaminLogSupabaseDatasource _remote;
  final String _userId;
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
  SyncOperation _op(VitaminLogDto d) => SyncOperation(
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
      'vitaminId': d.vitaminId,
      'date': d.date.toIso8601String(),
      'status': d.status.name,
      'createdAt': d.syncMetadata.createdAt.toIso8601String(),
    },
  );
  VitaminLogDto _dto(SyncOperation o) => VitaminLogDto(
    id: o.recordId,
    vitaminId: o.payload['vitaminId'] as String,
    date: DateTime.parse(o.payload['date'] as String),
    status: VitaminStatus.values.firstWhere(
      (v) => v.name == o.payload['status'],
      orElse: () => VitaminStatus.pending,
    ),
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
