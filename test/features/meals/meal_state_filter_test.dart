import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/meals/domain/entities/entities.dart';
import 'package:helpbari/features/meals/domain/value_objects/value_objects.dart';
import 'package:helpbari/features/meals/presentation/states/meal_state.dart';

void main() {
  test('filters history by date and meal type together', () {
    final meals = [
      _meal('breakfast', MealType.breakfast, DateTime(2026, 7, 12, 8)),
      _meal('lunch', MealType.lunch, DateTime(2026, 7, 12, 12)),
      _meal('old-lunch', MealType.lunch, DateTime(2026, 7, 11, 12)),
    ];
    final state = MealState(
      meals: meals,
      typeFilter: MealType.lunch,
      dateFilter: DateTime(2026, 7, 12),
    );

    expect(state.filteredMeals.map((meal) => meal.id), ['lunch']);
  });
}

Meal _meal(String id, MealType type, DateTime date) => Meal(
  id: id,
  name: MealName.create('Refeição $id')!,
  type: type,
  mealDate: MealDate(date),
);
