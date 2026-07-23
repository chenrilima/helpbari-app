import '../../../../core/sync/sync.dart';
import '../../domain/value_objects/medication_status.dart';
import '../datasources/drift_medication_log_local_datasource.dart';
import '../datasources/medication_log_supabase_datasource.dart';
import '../dtos/medication_log_dto.dart';

class MedicationLogSyncRepository
    implements
        SyncableRepository,
        RepositorySyncCursor,
        AtomicRemoteSyncRepository {
  const MedicationLogSyncRepository({
    required Future<DriftMedicationLogLocalDatasource> Function() local,
    required MedicationLogSupabaseDatasource remote,
    required String userId,
  }) : _local = local,
       _remote = remote,
       _userId = userId;
  static const key = 'medication_logs';
  final Future<DriftMedicationLogLocalDatasource> Function() _local;
  final MedicationLogSupabaseDatasource _remote;
  final String _userId;
  @override
  String get syncKey => key;
  @override
  Future<List<SyncOperation>> pendingOperations() async =>
      (await (await _local()).pendingSync()).map(_op).toList();
  @override
  Future<SyncOperation?> localOperationById(String id) async {
    final d = await (await _local()).pendingById(id);
    return d == null ? null : _op(d);
  }

  @override
  Future<void> push(SyncOperation o) async => (await _local()).applyRemote(
    await _remote.upsert(_dto(o), userId: _userId),
  );
  @override
  Future<List<SyncOperation>> pull({DateTime? updatedAfter}) async =>
      (await _remote.pull(
        userId: _userId,
        updatedAfter: updatedAfter,
      )).map(_op).toList();
  @override
  Future<void> applyRemote(SyncOperation o) async =>
      (await _local()).applyRemote(_dto(o));
  @override
  Future<void> applyRemoteAndMarkSynced(
    SyncOperation o, {
    required DateTime syncedAt,
  }) async => (await _local()).applyRemoteAndMarkSynced(_dto(o));
  @override
  Future<void> markSynced(String id, {required DateTime syncedAt}) async =>
      (await _local()).markSynced(id);
  @override
  Future<void> markFailed(String id, SyncError e) async =>
      (await _local()).markFailed(id, e.message);
  @override
  Future<DateTime?> getLastPullAt() async =>
      (await _local()).getLastPullAt(key);
  @override
  Future<void> saveSuccessfulSync(DateTime at) async =>
      (await _local()).saveCursor(key, at);
  SyncOperation _op(MedicationLogDto d) => SyncOperation(
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
    serverRevision: d.syncMetadata.serverRevision,
    payload: {
      'medicationId': d.medicationId,
      'date': d.date.toIso8601String(),
      'status': d.status.name,
      'createdAt': d.syncMetadata.createdAt.toIso8601String(),
    },
  );
  MedicationLogDto _dto(SyncOperation o) => MedicationLogDto(
    id: o.recordId,
    medicationId: o.payload['medicationId'] as String,
    date: DateTime.parse(o.payload['date'] as String),
    status: MedicationStatus.values.firstWhere(
      (v) => v.name == o.payload['status'],
      orElse: () => MedicationStatus.pending,
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
