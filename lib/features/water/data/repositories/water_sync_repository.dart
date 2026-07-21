import '../../../../core/sync/sync.dart';
import '../datasources/drift_water_local_datasource.dart';
import '../datasources/water_supabase_datasource.dart';
import '../dtos/water_record_dto.dart';

class WaterSyncRepository
    implements
        SyncableRepository,
        PagedPullSyncRepository,
        RepositorySyncCursor,
        AtomicRemoteSyncRepository {
  const WaterSyncRepository({
    required Future<DriftWaterLocalDatasource> Function() localDatasource,
    required WaterSupabaseDatasource supabaseDatasource,
    required String userId,
    SyncStatusMapper statusMapper = const SyncStatusMapper(),
  }) : _localDatasource = localDatasource,
       _supabaseDatasource = supabaseDatasource,
       _userId = userId,
       _statusMapper = statusMapper;

  static const key = 'water';

  final Future<DriftWaterLocalDatasource> Function() _localDatasource;
  final WaterSupabaseDatasource _supabaseDatasource;
  final String _userId;
  final SyncStatusMapper _statusMapper;

  @override
  String get syncKey => key;

  @override
  Future<List<SyncOperation>> pendingOperations() async {
    final records = await (await _localDatasource()).pendingSync();

    return records.map(_operationFromDto).toList();
  }

  @override
  Future<SyncOperation?> localOperationById(String recordId) async {
    final record = await (await _localDatasource()).pendingById(recordId);
    if (record == null) return null;

    return _operationFromDto(record);
  }

  @override
  Future<void> push(SyncOperation operation) async {
    final record = _dtoFromOperation(operation);
    final remoteRecord = switch (operation.type) {
      SyncOperationType.create => await _supabaseDatasource.insert(
        record,
        userId: _userId,
      ),
      SyncOperationType.update => await _supabaseDatasource.update(
        record,
        userId: _userId,
      ),
      SyncOperationType.delete => await _supabaseDatasource.softDelete(
        record,
        userId: _userId,
      ),
    };

    await (await _localDatasource()).applyRemote(remoteRecord);
  }

  @override
  Future<List<SyncOperation>> pull({DateTime? updatedAfter}) async {
    final records = await _supabaseDatasource.pull(
      userId: _userId,
      updatedAfter: updatedAfter,
    );

    return records.map(_operationFromDto).toList();
  }

  @override
  Stream<List<SyncOperation>> pullPages({
    DateTime? updatedAfter,
    int pageSize = 500,
  }) => _supabaseDatasource
      .pullPages(
        userId: _userId,
        updatedAfter: updatedAfter,
        pageSize: pageSize,
      )
      .map((records) => records.map(_operationFromDto).toList(growable: false));

  @override
  Future<void> applyRemote(SyncOperation operation) async {
    await (await _localDatasource()).applyRemote(_dtoFromOperation(operation));
  }

  @override
  Future<void> markSynced(String recordId, {required DateTime syncedAt}) {
    return _localDatasource().then((value) => value.markSynced(recordId));
  }

  @override
  Future<void> markFailed(String recordId, SyncError error) {
    return _localDatasource().then(
      (value) => value.markFailed(recordId, error.message),
    );
  }

  @override
  Future<DateTime?> getLastPullAt() async =>
      (await _localDatasource()).getLastPullAt(syncKey);

  @override
  Future<void> saveSuccessfulSync(DateTime completedAt) async =>
      (await _localDatasource()).saveCursor(syncKey, completedAt);

  @override
  Future<void> applyRemoteAndMarkSynced(
    SyncOperation operation, {
    required DateTime syncedAt,
  }) async {
    await (await _localDatasource()).applyRemoteAndMarkSynced(
      _dtoFromOperation(operation),
    );
  }

  SyncOperation _operationFromDto(WaterRecordDto record) {
    final metadata = record.syncMetadata;
    final type = metadata.isDeleted
        ? SyncOperationType.delete
        : _statusMapper.operationTypeFromStatus(metadata.syncStatus);

    return SyncOperation(
      repositoryKey: syncKey,
      recordId: record.id,
      type: type,
      updatedAt: metadata.updatedAt,
      deletedAt: metadata.deletedAt,
      userId: metadata.userId ?? _userId,
      payload: {
        'amountInMl': record.amountInMl,
        'recordedAt': record.recordedAt.toIso8601String(),
        'createdAt': metadata.createdAt.toIso8601String(),
        'updatedAt': metadata.updatedAt.toIso8601String(),
        'deletedAt': metadata.deletedAt?.toIso8601String(),
      },
    );
  }

  WaterRecordDto _dtoFromOperation(SyncOperation operation) {
    final payload = operation.payload;

    return WaterRecordDto(
      id: operation.recordId,
      amountInMl: payload['amountInMl'] as int,
      recordedAt: DateTime.parse(payload['recordedAt'] as String),
      syncMetadata: SyncMetadata(
        id: operation.recordId,
        userId: operation.userId ?? _userId,
        createdAt: DateTime.parse(payload['createdAt'] as String),
        updatedAt: operation.updatedAt,
        deletedAt: operation.deletedAt,
        syncStatus: operation.syncStatus,
      ),
    );
  }
}
