import '../../../../core/sync/sync.dart';
import '../datasources/drift_meal_local_datasource.dart';
import '../datasources/meal_supabase_datasource.dart';
import '../dtos/meal_dto.dart';
import '../../domain/value_objects/value_objects.dart';

class MealSyncRepository
    implements
        SyncableRepository,
        PagedPullSyncRepository,
        RepositorySyncCursor,
        AtomicRemoteSyncRepository {
  const MealSyncRepository({
    required Future<DriftMealLocalDatasource> Function() local,
    required MealSupabaseDatasource remote,
    required String userId,
    SyncStatusMapper statusMapper = const SyncStatusMapper(),
  }) : _local = local,
       _remote = remote,
       _userId = userId,
       _statusMapper = statusMapper;
  static const key = 'meals';
  final Future<DriftMealLocalDatasource> Function() _local;
  final MealSupabaseDatasource _remote;
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
  Future<void> push(SyncOperation operation) async => (await _local())
      .applyRemote(await _remote.upsert(_dto(operation), userId: _userId));
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

  SyncOperation _operation(MealDto dto) => SyncOperation(
    repositoryKey: key,
    recordId: dto.id,
    type: dto.syncMetadata.isDeleted
        ? SyncOperationType.delete
        : _statusMapper.operationTypeFromStatus(dto.syncMetadata.syncStatus),
    updatedAt: dto.syncMetadata.updatedAt,
    deletedAt: dto.syncMetadata.deletedAt,
    userId: dto.syncMetadata.userId ?? _userId,
    payload: {
      'name': dto.name,
      'type': dto.type.name,
      'mealDate': dto.mealDate.toIso8601String(),
      'notes': dto.notes,
      'proteinGrams': dto.proteinGrams,
      'createdAt': dto.syncMetadata.createdAt.toIso8601String(),
    },
  );
  MealDto _dto(SyncOperation op) => MealDto(
    id: op.recordId,
    name: op.payload['name'] as String,
    type: MealType.values.firstWhere(
      (type) => type.name == op.payload['type'],
      orElse: () => MealType.snack,
    ),
    mealDate: DateTime.parse(op.payload['mealDate'] as String),
    notes: op.payload['notes'] as String?,
    proteinGrams: op.payload['proteinGrams'] as int?,
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
