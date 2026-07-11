import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/repository_backend.dart';
import '../../../../core/database/drift/consistency/water_local_snapshot.dart';
import '../../../../core/database/drift/drift_database_providers.dart';
import '../../../../core/services/service_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/local_water_datasource.dart';
import '../../data/datasources/drift_water_local_datasource.dart';
import '../../data/repositories/drift_primary_water_repository.dart';
import '../../domain/repositories/water_repository.dart';
import '../../domain/usecases/use_cases.dart';

final waterRepositoryProvider = Provider<WaterRepository>((ref) {
  final userId = ref.watch(authSessionProvider)?.id;
  ref.watch(repositoryBackendProvider);
  final effectiveUserId = userId ?? anonymousWaterUserId;
  return DriftPrimaryWaterRepository(
    driftDatasource: () async {
      if (!ref.read(driftAvailableProvider)) {
        throw StateError('Drift unavailable');
      }
      final database = await ref.read(appDatabaseProvider.future);
      return DriftWaterLocalDatasource(
        dao: database.waterDao,
        clock: ref.read(clockServiceProvider),
        userId: effectiveUserId,
      );
    },
    fallbackDatasource: LocalWaterDatasource(
      database: ref.watch(localDatabaseProvider),
      clock: ref.watch(clockServiceProvider),
      userId: userId,
    ),
    logger: ref.watch(loggerServiceProvider),
  );
});

final waterUseCasesProvider = Provider(
  (ref) => WaterUseCases(
    ref.read(waterRepositoryProvider),
    ref.read(clockServiceProvider),
  ),
);
