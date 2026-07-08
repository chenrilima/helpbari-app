import '../../domain/entities/entities.dart';

class MealState {
  const MealState({this.meals = const [], this.isLoading = false});

  final List<Meal> meals;
  final bool isLoading;

  bool get hasMeals => meals.isNotEmpty;

  Meal? get latestMeal {
    if (meals.isEmpty) return null;

    return meals.first;
  }

  int get todayCount {
    return meals.where((meal) => meal.wasRegisteredToday).length;
  }

  int get totalProteinToday {
    return meals
        .where((meal) => meal.wasRegisteredToday)
        .fold<int>(0, (total, meal) => total + (meal.proteinGrams ?? 0));
  }

  MealState copyWith({List<Meal>? meals, bool? isLoading}) {
    return MealState(
      meals: meals ?? this.meals,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
