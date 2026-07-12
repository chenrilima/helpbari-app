import '../../../../core/sync/sync.dart';
import '../datasources/drift_exam_local_datasource.dart';
import '../datasources/exam_supabase_datasource.dart';
import '../dtos/exam_dto.dart';

class ExamSyncRepository
    implements
        SyncableRepository,
        RepositorySyncCursor,
        AtomicRemoteSyncRepository {
  const ExamSyncRepository({
    required Future<DriftExamLocalDatasource> Function() local,
    required ExamSupabaseDatasource remote,
    required String userId,
    SyncStatusMapper mapper = const SyncStatusMapper(),
  }) : _local = local,
       _remote = remote,
       _userId = userId,
       _mapper = mapper;
  static const key = 'exams';
  final Future<DriftExamLocalDatasource> Function() _local;
  final ExamSupabaseDatasource _remote;
  final String _userId;
  final SyncStatusMapper _mapper;
  @override
  String get syncKey => key;
  @override
  Future<List<SyncOperation>> pendingOperations() async =>
      (await (await _local()).pendingSync()).map(_operation).toList();
  @override
  Future<SyncOperation?> localOperationById(String id) async {
    final d = await (await _local()).pendingById(id);
    return d == null ? null : _operation(d);
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
      )).map(_operation).toList();
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
  SyncOperation _operation(ExamDto d) => SyncOperation(
    repositoryKey: key,
    recordId: d.id,
    type: d.syncMetadata.isDeleted
        ? SyncOperationType.delete
        : _mapper.operationTypeFromStatus(d.syncMetadata.syncStatus),
    updatedAt: d.syncMetadata.updatedAt,
    deletedAt: d.syncMetadata.deletedAt,
    userId: d.syncMetadata.userId ?? _userId,
    payload: {
      'name': d.name,
      'examDate': d.examDate.toIso8601String(),
      'laboratory': d.laboratory,
      'notes': d.notes,
      'attachmentPath': d.attachmentPath,
      'createdAt': d.syncMetadata.createdAt.toIso8601String(),
    },
  );
  ExamDto _dto(SyncOperation o) => ExamDto(
    id: o.recordId,
    name: o.payload['name'] as String,
    examDate: DateTime.parse(o.payload['examDate'] as String),
    laboratory: o.payload['laboratory'] as String?,
    notes: o.payload['notes'] as String?,
    attachmentPath: o.payload['attachmentPath'] as String?,
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
