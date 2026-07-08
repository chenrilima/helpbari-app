import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/fake_meal_repository.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/use_cases.dart';

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return FakeMealRepository();
});

final mealUseCasesProvider = Provider<MealUseCases>((ref) {
  return MealUseCases(ref.read(mealRepositoryProvider));
});
