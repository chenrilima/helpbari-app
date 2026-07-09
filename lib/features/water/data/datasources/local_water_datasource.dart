import '../../../../core/database/database.dart';
import '../../../../core/services/clock_service.dart';
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
}
