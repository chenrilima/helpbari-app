import '../../../../core/database/database.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/sync/sync.dart';
import '../dtos/weight_record_dto.dart';

class LocalWeightDatasource {
  const LocalWeightDatasource({
    required LocalDatabase database,
    required ClockService clock,
  }) : _database = database,
       _clock = clock;

  static const collection = 'weight_records';

  final LocalDatabase _database;
  final ClockService _clock;

  Future<List<WeightRecordDto>> getHistory() async {
    final records = await _database.getAll(collection);
    final activeRecords = records.where((record) => !record.isDeleted).toList()
      ..sort((a, b) {
        final aDate = DateTime.parse(a.data['recordedAt'] as String);
        final bDate = DateTime.parse(b.data['recordedAt'] as String);

        return bDate.compareTo(aDate);
      });

    return activeRecords.map(WeightRecordDto.fromRecord).toList();
  }

  Future<void> save(WeightRecordDto record) async {
    final previous = await _database.getById(collection, record.id);
    final dto = WeightRecordDto.fromEntity(
      record.toEntity(clock: _clock),
      now: _clock.now(),
      previousMetadata: previous?.metadata,
    );

    await _database.upsert(collection, dto.toRecord());
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
}
