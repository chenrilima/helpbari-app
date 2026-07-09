import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/local_weight_datasource.dart';
import '../dtos/weight_record_dto.dart';

class LocalWeightRepository implements WeightRepository {
  const LocalWeightRepository(this._datasource);

  final LocalWeightDatasource _datasource;

  @override
  Future<List<WeightRecord>> getHistory() async {
    final records = await _datasource.getHistory();

    return records.map((record) => record.toEntity()).toList();
  }

  @override
  Future<void> register(WeightRecord record) {
    return _datasource.save(
      WeightRecordDto.fromEntity(record, now: DateTime.now()),
    );
  }

  @override
  Future<void> update(WeightRecord record) {
    return _datasource.save(
      WeightRecordDto.fromEntity(record, now: DateTime.now()),
    );
  }

  @override
  Future<void> delete(String id) {
    return _datasource.delete(id);
  }
}
