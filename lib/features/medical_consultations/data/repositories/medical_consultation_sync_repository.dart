import '../../../../core/sync/sync.dart';
import '../datasources/drift_medical_consultation_local_datasource.dart';
import '../datasources/medical_consultation_supabase_datasource.dart';
import '../dtos/medical_consultation_dto.dart';

class MedicalConsultationSyncRepository
    implements
        SyncableRepository,
        RepositorySyncCursor,
        AtomicRemoteSyncRepository {
  const MedicalConsultationSyncRepository({
    required Future<DriftMedicalConsultationLocalDatasource> Function() local,
    required MedicalConsultationSupabaseDatasource remote,
    required String userId,
  }) : _local = local,
       _remote = remote,
       _userId = userId;

  static const key = 'medical_consultations';

  final Future<DriftMedicalConsultationLocalDatasource> Function() _local;
  final MedicalConsultationSupabaseDatasource _remote;
  final String _userId;

  @override
  String get syncKey => key;

  @override
  Future<List<SyncOperation>> pendingOperations() async =>
      (await (await _local()).pendingSync()).map(_op).toList(growable: false);

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
      )).map(_op).toList(growable: false);

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

  SyncOperation _op(MedicalConsultationDto dto) => SyncOperation(
    repositoryKey: key,
    recordId: dto.consultation.id,
    type: dto.syncMetadata.isDeleted
        ? SyncOperationType.delete
        : const SyncStatusMapper().operationTypeFromStatus(
            dto.syncMetadata.syncStatus,
          ),
    updatedAt: dto.syncMetadata.updatedAt,
    deletedAt: dto.syncMetadata.deletedAt,
    userId: dto.syncMetadata.userId ?? _userId,
    payload: {
      ...dto.toSupabaseRow(userId: _userId),
      'related_exam_ids': dto.consultation.relatedExamIds,
      'related_body_composition_ids':
          dto.consultation.relatedBodyCompositionIds,
    },
  );

  MedicalConsultationDto _dto(
    SyncOperation operation,
  ) => MedicalConsultationDto.fromSupabaseRow(
    operation.payload,
    relatedExamIds: (operation.payload['related_exam_ids'] as List? ?? const [])
        .cast<String>(),
    relatedBodyCompositionIds:
        (operation.payload['related_body_composition_ids'] as List? ?? const [])
            .cast<String>(),
  );
}
