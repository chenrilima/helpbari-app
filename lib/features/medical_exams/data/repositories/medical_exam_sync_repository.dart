import '../../../../core/sync/sync.dart';
import '../datasources/drift_medical_exam_local_datasource.dart';
import '../datasources/medical_exam_supabase_datasource.dart';
import '../dtos/medical_exam_dto.dart';

class MedicalExamSyncRepository
    implements
        SyncableRepository,
        RepositorySyncCursor,
        AtomicRemoteSyncRepository {
  const MedicalExamSyncRepository({
    required Future<DriftMedicalExamLocalDatasource> Function() local,
    required MedicalExamSupabaseDatasource remote,
    required String userId,
    SyncStatusMapper mapper = const SyncStatusMapper(),
  }) : _local = local,
       _remote = remote,
       _userId = userId,
       _mapper = mapper;

  static const key = 'medical_exams';

  final Future<DriftMedicalExamLocalDatasource> Function() _local;
  final MedicalExamSupabaseDatasource _remote;
  final String _userId;
  final SyncStatusMapper _mapper;

  @override
  String get syncKey => key;

  @override
  Future<List<SyncOperation>> pendingOperations() async =>
      (await (await _local()).pendingSync()).map(_op).toList(growable: false);

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

  SyncOperation _op(MedicalExamDto dto) => SyncOperation(
    repositoryKey: key,
    recordId: dto.exam.id,
    type: dto.syncMetadata.isDeleted
        ? SyncOperationType.delete
        : _mapper.operationTypeFromStatus(dto.syncMetadata.syncStatus),
    updatedAt: dto.syncMetadata.updatedAt,
    deletedAt: dto.syncMetadata.deletedAt,
    userId: dto.syncMetadata.userId ?? _userId,
    payload: {
      'exam': dto.toSupabaseRow(userId: dto.syncMetadata.userId ?? _userId),
      'results': dto.results
          .map(
            (item) =>
                item.toSupabaseRow(userId: dto.syncMetadata.userId ?? _userId),
          )
          .toList(growable: false),
    },
  );

  MedicalExamDto _dto(SyncOperation operation) =>
      MedicalExamDto.fromSupabaseRow(
        exam: Map<String, dynamic>.from(operation.payload['exam'] as Map),
        results: (operation.payload['results'] as List? ?? const [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList(growable: false),
      );
}
