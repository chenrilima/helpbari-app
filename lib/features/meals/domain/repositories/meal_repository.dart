import '../entities/entities.dart';

abstract interface class MealRepository {
  Future<List<Meal>> getAll();

  Future<void> save(Meal meal);

  Future<void> update(Meal meal);

  Future<void> delete(String id);
}

abstract interface class MealRangeRepository {
  Future<List<Meal>> getByPeriod(
    DateTime startInclusive,
    DateTime endExclusive, {
    required int limit,
  });
}
