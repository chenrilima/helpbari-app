import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/clock_service.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../core/services/uuid_service.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/use_cases.dart';
import '../../domain/value_objects/value_objects.dart';
import '../providers/meal_use_cases_provider.dart';
import '../states/meal_state.dart';

class MealViewModel extends Notifier<MealState> {
  late final UuidService _uuidService;
  late final LoggerService _logger;
  late final ClockService _clock;
  late final MealUseCases _useCases;

  @override
  MealState build() {
    _useCases = ref.read(mealUseCasesProvider);
    _uuidService = ref.read(uuidServiceProvider);
    _logger = ref.read(loggerServiceProvider);
    _clock = ref.read(clockServiceProvider);
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
      id: _uuidService.generate(),
      name: mealName,
      type: type,
      mealDate: MealDate(mealDate, clock: _clock),
      notes: notes,
      proteinGrams: proteinGrams,
    );

    await _useCases.save(meal);
    await loadMeals();
    _logger.info('Refeição cadastrada.');
  }
}
