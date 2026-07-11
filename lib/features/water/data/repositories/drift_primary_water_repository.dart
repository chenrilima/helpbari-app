import '../../../../core/services/logger_service.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/water_repository.dart';
import '../datasources/drift_water_local_datasource.dart';
import '../datasources/local_water_datasource.dart';
import '../dtos/water_record_dto.dart';

typedef DriftWaterDatasourceFactory =
    Future<DriftWaterLocalDatasource> Function();

class DriftPrimaryWaterRepository implements WaterRepository {
  const DriftPrimaryWaterRepository({
    required DriftWaterDatasourceFactory driftDatasource,
    required LocalWaterDatasource fallbackDatasource,
    required LoggerService logger,
  }) : _driftDatasource = driftDatasource,
       _fallbackDatasource = fallbackDatasource,
       _logger = logger;

  final DriftWaterDatasourceFactory _driftDatasource;
  final LocalWaterDatasource _fallbackDatasource;
  final LoggerService _logger;

  @override
  Future<List<WaterRecord>> getHistory() async {
    try {
      return (await (await _driftDatasource()).getHistory())
          .map((dto) => dto.toEntity())
          .toList();
    } catch (error) {
      _logger.warning(
        'Water local database unavailable; read fallback enabled (${error.runtimeType}).',
      );
      return (await _fallbackDatasource.getHistory())
          .map((dto) => dto.toEntity())
          .toList();
    }
  }

  @override
  Future<void> create(WaterRecord record) => _write(record);

  @override
  Future<void> update(WaterRecord record) => _write(record);

  Future<void> _write(WaterRecord record) async {
    final datasource = await _driftDatasource();
    await datasource.save(
      WaterRecordDto.fromEntity(record, now: DateTime.now()),
    );
  }

  @override
  Future<void> delete(String id) async => (await _driftDatasource()).delete(id);
}
