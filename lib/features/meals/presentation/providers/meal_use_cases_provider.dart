import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/repository_backend.dart';
import '../../../../core/services/service_providers.dart';
import '../../data/datasources/local_meal_datasource.dart';
import '../../data/repositories/fake_meal_repository.dart';
import '../../data/repositories/local_meal_repository.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/use_cases.dart';

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return switch (ref.watch(repositoryBackendProvider)) {
    RepositoryBackend.fake => FakeMealRepository(),
    RepositoryBackend.local => LocalMealRepository(
      LocalMealDatasource(
        database: ref.watch(localDatabaseProvider),
        clock: ref.watch(clockServiceProvider),
      ),
    ),
    RepositoryBackend.supabase => throw UnsupportedError(
      'Meal Supabase repository will be enabled in the Supabase integration step.',
    ),
  };
});

final mealUseCasesProvider = Provider<MealUseCases>((ref) {
  return MealUseCases(ref.read(mealRepositoryProvider));
});
