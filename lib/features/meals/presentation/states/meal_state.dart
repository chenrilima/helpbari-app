import '../../domain/entities/entities.dart';

import '../../domain/value_objects/value_objects.dart';

class MealState {
  const MealState({
    this.meals = const [],
    this.isLoading = false,
    this.errorMessage,
    this.syncWarning,
    this.typeFilter,
    this.dateFilter,
  });

  final List<Meal> meals;
  final bool isLoading;
  final String? errorMessage;
  final String? syncWarning;
  final MealType? typeFilter;
  final DateTime? dateFilter;

  List<Meal> get filteredMeals => meals.where((meal) {
    final matchesType = typeFilter == null || meal.type == typeFilter;
    final date = dateFilter;
    final value = meal.mealDate.value;
    final matchesDate =
        date == null ||
        (value.year == date.year &&
            value.month == date.month &&
            value.day == date.day);
    return matchesType && matchesDate;
  }).toList();

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

  MealState copyWith({
    List<Meal>? meals,
    bool? isLoading,
    String? errorMessage,
    String? syncWarning,
    MealType? typeFilter,
    DateTime? dateFilter,
    bool clearError = false,
    bool clearWarning = false,
    bool clearTypeFilter = false,
    bool clearDateFilter = false,
  }) {
    return MealState(
      meals: meals ?? this.meals,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      syncWarning: clearWarning ? null : syncWarning ?? this.syncWarning,
      typeFilter: clearTypeFilter ? null : typeFilter ?? this.typeFilter,
      dateFilter: clearDateFilter ? null : dateFilter ?? this.dateFilter,
    );
  }
}
