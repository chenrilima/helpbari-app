import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/entities.dart';
import '../../domain/usecases/use_cases.dart';
import '../../domain/value_objects/value_objects.dart';
import '../providers/meal_use_cases_provider.dart';
import '../states/meal_state.dart';

class MealViewModel extends Notifier<MealState> {
  final _uuid = const Uuid();

  late final MealUseCases _useCases;

  @override
  MealState build() {
    _useCases = ref.read(mealUseCasesProvider);

    return const MealState();
  }

  Future<void> loadMeals() async {
    state = state.copyWith(isLoading: true);

    final meals = await _useCases.getAll();

    state = state.copyWith(meals: meals, isLoading: false);
  }

  Future<void> createMeal({
    required String name,
    required MealType type,
    required DateTime mealDate,
    String? notes,
    int? proteinGrams,
  }) async {
    final mealName = MealName.create(name);

    if (mealName == null) return;

    final meal = Meal(
      id: _uuid.v4(),
      name: mealName,
      type: type,
      mealDate: MealDate(mealDate),
      notes: notes,
      proteinGrams: proteinGrams,
    );

    await _useCases.save(meal);
    await loadMeals();
  }
}
