import '../../../../core/services/logger_service.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/weight_repository.dart';
import '../datasources/drift_weight_local_datasource.dart';
import '../datasources/local_weight_datasource.dart';
import '../dtos/weight_record_dto.dart';

typedef EnsureWeightCutover = Future<void> Function();
typedef HasWeightCutoverMirror = bool Function();
Future<void> _noop() async {}
bool _noMirror() => false;

class DriftPrimaryWeightRepository
    implements WeightRepository, WeightRangeRepository {
  const DriftPrimaryWeightRepository({
    required Future<DriftWeightLocalDatasource> Function() drift,
    required LocalWeightDatasource fallback,
    required LoggerService logger,
    EnsureWeightCutover ensureCutover = _noop,
    HasWeightCutoverMirror hasCutoverMirror = _noMirror,
  }) : _drift = drift,
       _fallback = fallback,
       _logger = logger,
       _ensureCutover = ensureCutover,
       _hasCutoverMirror = hasCutoverMirror;
  final Future<DriftWeightLocalDatasource> Function() _drift;
  final LocalWeightDatasource _fallback;
  final LoggerService _logger;
  final EnsureWeightCutover _ensureCutover;
  final HasWeightCutoverMirror _hasCutoverMirror;
  Future<DriftWeightLocalDatasource> _resolve() async {
    final value = await _drift();
    await _ensureCutover();
    return value;
  }

  @override
  Future<List<WeightRecord>> getHistory() async {
    try {
      return (await (await _resolve()).getHistory())
          .map((e) => e.toEntity())
          .toList();
    } catch (error) {
      if (_hasCutoverMirror()) {
        throw StateError(
          'Weight indisponível temporariamente no armazenamento local.',
        );
      }
      _logger.warning(
        'Weight Drift unavailable; legacy read fallback (${error.runtimeType}).',
      );
      return (await _fallback.getHistory()).map((e) => e.toEntity()).toList();
    }
  }

  @override
  Future<List<WeightRecord>> getByPeriod(
    DateTime startInclusive,
    DateTime endExclusive, {
    required int limit,
  }) async => (await (await _resolve()).getByPeriod(
    startInclusive,
    endExclusive,
    limit: limit,
  )).map((dto) => dto.toEntity()).toList();

  @override
  Future<WeightRecord?> getLatest() async =>
      (await (await _resolve()).getLatest())?.toEntity();

  Future<void> _save(WeightRecord record) async => (await _resolve()).save(
    WeightRecordDto.fromEntity(record, now: DateTime.now()),
  );
  @override
  Future<void> register(WeightRecord record) => _save(record);
  @override
  Future<void> update(WeightRecord record) => _save(record);
  @override
  Future<void> delete(String id) async => (await _resolve()).delete(id);
}
