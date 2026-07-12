import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/repository_backend.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../core/database/drift/drift_database_providers.dart';
import '../../../../core/database/drift/cutover/meal_cutover_service.dart';
import '../../../../core/database/drift/migrations/meal_legacy_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/drift_meal_local_datasource.dart';
import '../../data/datasources/local_meal_datasource.dart';
import '../../data/repositories/drift_primary_meal_repository.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/use_cases.dart';

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  ref.watch(repositoryBackendProvider);
  final userId = ref.watch(authSessionProvider)?.id;
  final effectiveUserId = userId ?? anonymousMealUserId;
  final storage = ref.watch(localStorageServiceProvider);
  return DriftPrimaryMealRepository(
    drift: () async => DriftMealLocalDatasource(
      dao: (await ref.read(appDatabaseProvider.future)).mealDao,
      clock: ref.read(clockServiceProvider),
      userId: effectiveUserId,
    ),
    fallback: LocalMealDatasource(
      database: ref.watch(localDatabaseProvider),
      clock: ref.watch(clockServiceProvider),
    ),
    logger: ref.watch(loggerServiceProvider),
    ensureCutover: () async {
      if (userId != null) {
        await MealCutoverService(
          database: await ref.read(appDatabaseProvider.future),
          storage: storage,
        ).attempt(userId);
      }
    },
    hasCutoverMirror: () =>
        userId != null &&
        MealCutoverService.isCompletedMirrorFor(storage, userId),
  );
});

final mealUseCasesProvider = Provider<MealUseCases>((ref) {
  return MealUseCases(ref.watch(mealRepositoryProvider));
});
