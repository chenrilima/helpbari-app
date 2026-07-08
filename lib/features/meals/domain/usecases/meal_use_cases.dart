import '../entities/entities.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';

class MealUseCases {
  const MealUseCases(this._repository);

  final MealRepository _repository;

  Future<List<Meal>> getAll() {
    return _repository.getAll();
  }

  Future<void> save(Meal meal) {
    return _repository.save(meal);
  }

  Future<void> update(Meal meal) {
    return _repository.update(meal);
  }

  Future<void> delete(String id) {
    return _repository.delete(id);
  }

  Future<MealSummary> getSummary() async {
    final meals = await _repository.getAll();

    final todayMeals = meals.where((meal) => meal.wasRegisteredToday).toList();

    final totalProteinToday = todayMeals.fold<int>(
      0,
      (total, meal) => total + (meal.proteinGrams ?? 0),
    );

    return MealSummary(
      latestMeal: meals.isEmpty ? null : meals.first,
      todayCount: todayMeals.length,
      totalProteinToday: totalProteinToday,
      hasMeals: meals.isNotEmpty,
    );
  }
}
