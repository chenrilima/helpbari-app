import '../../../../core/database/database.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/sync/sync.dart';
import '../dtos/water_record_dto.dart';

class LocalWaterDatasource {
  const LocalWaterDatasource({
    required LocalDatabase database,
    required ClockService clock,
    this.userId,
  }) : _database = database,
       _clock = clock;

  static const collection = 'water_records';

  final LocalDatabase _database;
  final ClockService _clock;
  final String? userId;

  Future<List<WaterRecordDto>> getHistory() async {
    final records = await _database.getAll(collection);
    final activeRecords =
        records
            .where(
              (record) =>
                  !record.isDeleted &&
                  (userId == null || record.metadata.userId == userId),
            )
            .toList()
          ..sort((a, b) {
            final aDate = DateTime.parse(a.data['recordedAt'] as String);
            final bDate = DateTime.parse(b.data['recordedAt'] as String);

            return bDate.compareTo(aDate);
          });

    return activeRecords.map(WaterRecordDto.fromRecord).toList();
  }

  Future<void> save(WaterRecordDto record) async {
    final previous = await _database.getById(collection, record.id);
    final dto = WaterRecordDto.fromEntity(
      record.toEntity(clock: _clock),
      now: _clock.now(),
      userId: userId,
      previousMetadata: previous?.metadata,
    );

    await _database.upsert(collection, dto.toRecord());
  }

  Future<List<WaterRecordDto>> pendingSync() async {
    final records = await _database.getAll(collection);

    return records
        .where(
          (record) =>
              (userId == null || record.metadata.userId == userId) &&
              switch (record.metadata.syncStatus) {
                SyncStatus.pendingCreate ||
                SyncStatus.pendingUpdate ||
                SyncStatus.pendingDelete ||
                SyncStatus.failed => true,
                SyncStatus.synced => false,
              },
        )
        .map(_pendingDto)
        .toList();
  }

  Future<WaterRecordDto?> pendingById(String id) async {
    final record = await _database.getById(collection, id);
    if (record == null) return null;
    if (userId != null && record.metadata.userId != userId) return null;

    return switch (record.metadata.syncStatus) {
      SyncStatus.pendingCreate ||
      SyncStatus.pendingUpdate ||
      SyncStatus.pendingDelete ||
      SyncStatus.failed => _pendingDto(record),
      SyncStatus.synced => null,
    };
  }

  Future<void> applyRemote(WaterRecordDto record) async {
    if (userId != null && record.syncMetadata.userId != userId) return;
    await _database.upsert(collection, record.toRecord());
  }

  Future<void> delete(String id) async {
    final previous = await _database.getById(collection, id);
    if (previous == null) return;
    if (userId != null && previous.metadata.userId != userId) return;

    final now = _clock.now();

    await _database.upsert(
      collection,
      previous.copyWith(
        metadata: previous.metadata.copyWith(
          updatedAt: now,
          deletedAt: now,
          syncStatus: SyncStatus.pendingDelete,
        ),
      ),
    );
  }

  Future<void> markSynced(String id, {required String userId}) async {
    final previous = await _database.getById(collection, id);
    if (previous == null) return;

    final data = Map<String, dynamic>.from(previous.data)
      ..remove('_failedSyncStatus');
    await _database.upsert(
      collection,
      previous.copyWith(
        data: data,
        metadata: previous.metadata.copyWith(
          userId: userId,
          syncStatus: SyncStatus.synced,
        ),
      ),
    );
  }

  Future<void> markFailed(String id) async {
    final previous = await _database.getById(collection, id);
    if (previous == null) return;

    final data = Map<String, dynamic>.from(previous.data)
      ..['_failedSyncStatus'] =
          previous.data['_failedSyncStatus'] ??
          previous.metadata.syncStatus.name;
    await _database.upsert(
      collection,
      previous.copyWith(
        data: data,
        metadata: previous.metadata.copyWith(syncStatus: SyncStatus.failed),
      ),
    );
  }

  WaterRecordDto _pendingDto(LocalDatabaseRecord record) {
    if (record.metadata.syncStatus != SyncStatus.failed) {
      return WaterRecordDto.fromRecord(record);
    }
    final originalStatus = SyncStatus.fromName(
      record.data['_failedSyncStatus'] as String?,
    );
    return WaterRecordDto.fromRecord(
      record.copyWith(
        metadata: record.metadata.copyWith(syncStatus: originalStatus),
      ),
    );
  }
}
