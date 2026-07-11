import '../../../../core/sync/sync.dart';
import '../datasources/local_water_datasource.dart';
import '../datasources/water_supabase_datasource.dart';
import '../dtos/water_record_dto.dart';

class WaterSyncRepository implements SyncableRepository {
  const WaterSyncRepository({
    required LocalWaterDatasource localDatasource,
    required WaterSupabaseDatasource supabaseDatasource,
    required String userId,
    SyncStatusMapper statusMapper = const SyncStatusMapper(),
  }) : _localDatasource = localDatasource,
       _supabaseDatasource = supabaseDatasource,
       _userId = userId,
       _statusMapper = statusMapper;

  static const key = 'water_records';

  final LocalWaterDatasource _localDatasource;
  final WaterSupabaseDatasource _supabaseDatasource;
  final String _userId;
  final SyncStatusMapper _statusMapper;

  @override
  String get syncKey => key;

  @override
  Future<List<SyncOperation>> pendingOperations() async {
    final records = await _localDatasource.pendingSync();

    return records.map(_operationFromDto).toList();
  }

  @override
  Future<SyncOperation?> localOperationById(String recordId) async {
    final record = await _localDatasource.pendingById(recordId);
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

    await _localDatasource.applyRemote(remoteRecord);
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
  Future<void> applyRemote(SyncOperation operation) async {
    await _localDatasource.applyRemote(_dtoFromOperation(operation));
  }

  @override
  Future<void> markSynced(String recordId, {required DateTime syncedAt}) {
    return _localDatasource.markSynced(recordId, userId: _userId);
  }

  @override
  Future<void> markFailed(String recordId, SyncError error) {
    return _localDatasource.markFailed(recordId);
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
