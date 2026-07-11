import '../../domain/entities/entities.dart';
import '../../domain/repositories/water_repository.dart';
import '../datasources/local_water_datasource.dart';
import '../dtos/water_record_dto.dart';

class LocalWaterRepository implements WaterRepository {
  const LocalWaterRepository(this._datasource);

  final LocalWaterDatasource _datasource;

  @override
  Future<List<WaterRecord>> getHistory() async {
    final records = await _datasource.getHistory();

    return records.map((record) => record.toEntity()).toList();
  }

  @override
  Future<void> create(WaterRecord record) {
    return _datasource.save(
      WaterRecordDto.fromEntity(record, now: DateTime.now()),
    );
  }

  @override
  Future<void> update(WaterRecord record) {
    return _datasource.save(
      WaterRecordDto.fromEntity(record, now: DateTime.now()),
    );
  }

  @override
  Future<void> delete(String id) => _datasource.delete(id);
}
