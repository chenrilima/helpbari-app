import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/local_meal_datasource.dart';
import '../dtos/meal_dto.dart';

class LocalMealRepository implements MealRepository {
  const LocalMealRepository(this._datasource);

  final LocalMealDatasource _datasource;

  @override
  Future<List<Meal>> getAll() async {
    final meals = await _datasource.getAll();

    return meals.map((meal) => meal.toEntity()).toList();
  }

  @override
  Future<void> save(Meal meal) {
    return _datasource.save(MealDto.fromEntity(meal, now: DateTime.now()));
  }

  @override
  Future<void> update(Meal meal) {
    return _datasource.save(MealDto.fromEntity(meal, now: DateTime.now()));
  }

  @override
  Future<void> delete(String id) {
    return _datasource.delete(id);
  }
}
