import '../../../../core/sync/sync.dart';
import '../datasources/drift_medical_prescription_local_datasource.dart';
import '../datasources/medical_prescription_supabase_datasource.dart';
import '../dtos/medical_prescription_dto.dart';

class MedicalPrescriptionSyncRepository
    implements
        SyncableRepository,
        RepositorySyncCursor,
        AtomicRemoteSyncRepository {
  const MedicalPrescriptionSyncRepository({
    required Future<DriftMedicalPrescriptionLocalDatasource> Function() local,
    required MedicalPrescriptionSupabaseDatasource remote,
    required String userId,
    SyncStatusMapper mapper = const SyncStatusMapper(),
  }) : _local = local,
       _remote = remote,
       _userId = userId,
       _mapper = mapper;

  static const key = 'medical_prescriptions';
  final Future<DriftMedicalPrescriptionLocalDatasource> Function() _local;
  final MedicalPrescriptionSupabaseDatasource _remote;
  final String _userId;
  final SyncStatusMapper _mapper;

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
  Future<void> push(SyncOperation operation) async => (await _local())
      .applyRemote(await _remote.upsert(_dto(operation), userId: _userId));
  @override
  Future<List<SyncOperation>> pull({DateTime? updatedAfter}) async =>
      (await _remote.pull(
        userId: _userId,
        updatedAfter: updatedAfter,
      )).map(_operation).toList(growable: false);
  @override
  Future<void> applyRemote(SyncOperation operation) async =>
      (await _local()).applyRemote(_dto(operation));
  @override
  Future<void> applyRemoteAndMarkSynced(
    SyncOperation operation, {
    required DateTime syncedAt,
  }) async {
    final local = await _local();
    await local.applyRemote(_dto(operation));
    await local.markSynced(operation.recordId);
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

  SyncOperation _operation(MedicalPrescriptionDto dto) => SyncOperation(
    repositoryKey: key,
    recordId: dto.prescription.id,
    type: dto.metadata.isDeleted
        ? SyncOperationType.delete
        : _mapper.operationTypeFromStatus(dto.metadata.syncStatus),
    updatedAt: dto.metadata.updatedAt,
    deletedAt: dto.metadata.deletedAt,
    userId: dto.prescription.userId,
    serverRevision: dto.metadata.serverRevision,
    payload: {
      'prescription': dto.toSupabasePrescriptionRow(),
      'items': dto.toSupabaseItemRows(),
    },
  );

  MedicalPrescriptionDto _dto(SyncOperation operation) =>
      MedicalPrescriptionDto.fromSupabaseRows(
        prescription: Map<String, dynamic>.from(
          operation.payload['prescription'] as Map,
        ),
        items: (operation.payload['items'] as List? ?? const [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList(growable: false),
      );
}
