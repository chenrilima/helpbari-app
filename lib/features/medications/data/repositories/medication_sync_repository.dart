import '../../../../core/sync/sync.dart';
import '../datasources/drift_medication_local_datasource.dart';
import '../datasources/medication_supabase_datasource.dart';
import '../dtos/medication_dto.dart';

class MedicationSyncRepository
    implements
        SyncableRepository,
        RepositorySyncCursor,
        AtomicRemoteSyncRepository {
  const MedicationSyncRepository({
    required Future<DriftMedicationLocalDatasource> Function() local,
    required MedicationSupabaseDatasource remote,
    required String userId,
    this.afterRemoteCommit,
  }) : _local = local,
       _remote = remote,
       _userId = userId;
  static const key = 'medications';
  final Future<DriftMedicationLocalDatasource> Function() _local;
  final MedicationSupabaseDatasource _remote;
  final String _userId;
  final Future<void> Function(MedicationDto)? afterRemoteCommit;
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
  }) async {
    final d = _dto(o);
    await (await _local()).applyRemoteAndMarkSynced(d);
    await afterRemoteCommit?.call(d);
  }

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
  SyncOperation _op(MedicationDto d) => SyncOperation(
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
      'name': d.name,
      'hour': d.hour,
      'minute': d.minute,
      'dosage': d.dosage,
      'notes': d.notes,
      'createdAt': d.syncMetadata.createdAt.toIso8601String(),
    },
  );
  MedicationDto _dto(SyncOperation o) => MedicationDto(
    id: o.recordId,
    name: o.payload['name'] as String,
    hour: o.payload['hour'] as int,
    minute: o.payload['minute'] as int,
    dosage: o.payload['dosage'] as String?,
    notes: o.payload['notes'] as String?,
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
