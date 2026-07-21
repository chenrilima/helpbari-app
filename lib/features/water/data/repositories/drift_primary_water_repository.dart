import '../../../../core/services/logger_service.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/water_repository.dart';
import '../datasources/drift_water_local_datasource.dart';
import '../datasources/local_water_datasource.dart';
import '../dtos/water_record_dto.dart';

typedef DriftWaterDatasourceFactory =
    Future<DriftWaterLocalDatasource> Function();
typedef EnsureWaterCutover = Future<void> Function();
typedef HasWaterCutoverMirror = bool Function();

Future<void> _noCutoverAction() async {}
bool _noCutoverMirror() => false;

class DriftPrimaryWaterRepository
    implements WaterRepository, WaterRangeRepository {
  const DriftPrimaryWaterRepository({
    required DriftWaterDatasourceFactory driftDatasource,
    required LocalWaterDatasource fallbackDatasource,
    required LoggerService logger,
    EnsureWaterCutover ensureCutover = _noCutoverAction,
    HasWaterCutoverMirror hasCutoverMirror = _noCutoverMirror,
  }) : _driftDatasource = driftDatasource,
       _fallbackDatasource = fallbackDatasource,
       _logger = logger,
       _ensureCutover = ensureCutover,
       _hasCutoverMirror = hasCutoverMirror;

  final DriftWaterDatasourceFactory _driftDatasource;
  final LocalWaterDatasource _fallbackDatasource;
  final LoggerService _logger;
  final EnsureWaterCutover _ensureCutover;
  final HasWaterCutoverMirror _hasCutoverMirror;

  @override
  Future<List<WaterRecord>> getHistory() async {
    try {
      return (await (await _resolveDrift()).getHistory())
          .map((dto) => dto.toEntity())
          .toList();
    } catch (error) {
      if (_hasCutoverMirror()) {
        throw WaterDriftUnavailableAfterCutoverException(error.runtimeType);
      }
      _logger.warning(
        'Water local database unavailable; read fallback enabled (${error.runtimeType}).',
      );
      return (await _fallbackDatasource.getHistory())
          .map((dto) => dto.toEntity())
          .toList();
    }
  }

  @override
  Future<List<WaterRecord>> getByPeriod(
    DateTime startInclusive,
    DateTime endExclusive, {
    required int limit,
  }) async => (await (await _resolveDrift()).getByPeriod(
    startInclusive,
    endExclusive,
    limit: limit,
  )).map((dto) => dto.toEntity()).toList();

  @override
  Future<void> create(WaterRecord record) => _write(record);

  @override
  Future<void> update(WaterRecord record) => _write(record);

  Future<void> _write(WaterRecord record) async {
    final datasource = await _resolveDrift();
    await datasource.save(
      WaterRecordDto.fromEntity(record, now: DateTime.now()),
    );
  }

  @override
  Future<void> delete(String id) async => (await _resolveDrift()).delete(id);

  Future<DriftWaterLocalDatasource> _resolveDrift() async {
    final datasource = await _driftDatasource();
    await _ensureCutover();
    return datasource;
  }
}

class WaterDriftUnavailableAfterCutoverException implements Exception {
  const WaterDriftUnavailableAfterCutoverException(this.causeType);
  final Type causeType;

  @override
  String toString() =>
      'Water indisponível temporariamente no armazenamento local.';
}
