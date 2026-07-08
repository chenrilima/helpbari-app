import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

class FakeMealRepository implements MealRepository {
  final List<Meal> _meals = [];

  @override
  Future<List<Meal>> getAll() async {
    final meals = [..._meals];

    meals.sort((a, b) => b.mealDate.value.compareTo(a.mealDate.value));

    return List.unmodifiable(meals);
  }

  @override
  Future<void> save(Meal meal) async {
    _meals.add(meal);
  }

  @override
  Future<void> update(Meal meal) async {
    final index = _meals.indexWhere((item) => item.id == meal.id);

    if (index == -1) return;

    _meals[index] = meal;
  }

  @override
  Future<void> delete(String id) async {
    _meals.removeWhere((item) => item.id == id);
  }
}
