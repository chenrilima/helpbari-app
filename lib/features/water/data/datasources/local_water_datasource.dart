import '../../../../core/database/database.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/sync/sync.dart';
import '../dtos/water_record_dto.dart';

class LocalWaterDatasource {
  const LocalWaterDatasource({
    required LocalDatabase database,
    required ClockService clock,
  }) : _database = database,
       _clock = clock;

  static const collection = 'water_records';

  final LocalDatabase _database;
  final ClockService _clock;

  Future<List<WaterRecordDto>> getHistory() async {
    final records = await _database.getAll(collection);
    final activeRecords = records.where((record) => !record.isDeleted).toList()
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
      previousMetadata: previous?.metadata,
    );

    await _database.upsert(collection, dto.toRecord());
  }

  Future<List<WaterRecordDto>> pendingSync() async {
    final records = await _database.getAll(collection);

    return records
        .where(
          (record) => switch (record.metadata.syncStatus) {
            SyncStatus.pendingCreate ||
            SyncStatus.pendingUpdate ||
            SyncStatus.pendingDelete => true,
            SyncStatus.synced || SyncStatus.failed => false,
          },
        )
        .map(WaterRecordDto.fromRecord)
        .toList();
  }

  Future<WaterRecordDto?> pendingById(String id) async {
    final record = await _database.getById(collection, id);
    if (record == null) return null;

    return switch (record.metadata.syncStatus) {
      SyncStatus.pendingCreate ||
      SyncStatus.pendingUpdate ||
      SyncStatus.pendingDelete => WaterRecordDto.fromRecord(record),
      SyncStatus.synced || SyncStatus.failed => null,
    };
  }

  Future<void> applyRemote(WaterRecordDto record) async {
    await _database.upsert(collection, record.toRecord());
  }

  Future<void> delete(String id) async {
    final previous = await _database.getById(collection, id);
    if (previous == null) return;

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

    await _database.upsert(
      collection,
      previous.copyWith(
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

    await _database.upsert(
      collection,
      previous.copyWith(
        metadata: previous.metadata.copyWith(syncStatus: SyncStatus.failed),
      ),
    );
  }
}
