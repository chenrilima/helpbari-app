import '../../../../core/services/logger_service.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/meal_repository.dart';
import '../datasources/drift_meal_local_datasource.dart';
import '../datasources/local_meal_datasource.dart';
import '../dtos/meal_dto.dart';

typedef EnsureMealCutover = Future<void> Function();
typedef HasMealCutoverMirror = bool Function();
Future<void> _noop() async {}
bool _noMirror() => false;

class DriftPrimaryMealRepository implements MealRepository {
  const DriftPrimaryMealRepository({
    required Future<DriftMealLocalDatasource> Function() drift,
    required LocalMealDatasource fallback,
    required LoggerService logger,
    EnsureMealCutover ensureCutover = _noop,
    HasMealCutoverMirror hasCutoverMirror = _noMirror,
  }) : _drift = drift,
       _fallback = fallback,
       _logger = logger,
       _ensureCutover = ensureCutover,
       _hasCutoverMirror = hasCutoverMirror;
  final Future<DriftMealLocalDatasource> Function() _drift;
  final LocalMealDatasource _fallback;
  final LoggerService _logger;
  final EnsureMealCutover _ensureCutover;
  final HasMealCutoverMirror _hasCutoverMirror;

  Future<DriftMealLocalDatasource> _resolve() async {
    final datasource = await _drift();
    await _ensureCutover();
    return datasource;
  }

  @override
  Future<List<Meal>> getAll() async {
    try {
      return (await (await _resolve()).getAll())
          .map((dto) => dto.toEntity())
          .toList();
    } catch (error) {
      if (_hasCutoverMirror()) {
        throw StateError(
          'Refeições indisponíveis temporariamente no armazenamento local.',
        );
      }
      _logger.warning(
        'Meals Drift unavailable; legacy read fallback (${error.runtimeType}).',
      );
      return (await _fallback.getAll()).map((dto) => dto.toEntity()).toList();
    }
  }

  Future<void> _save(Meal meal) async =>
      (await _resolve()).save(MealDto.fromEntity(meal, now: DateTime.now()));
  @override
  Future<void> save(Meal meal) => _save(meal);
  @override
  Future<void> update(Meal meal) => _save(meal);
  @override
  Future<void> delete(String id) async => (await _resolve()).delete(id);
}
