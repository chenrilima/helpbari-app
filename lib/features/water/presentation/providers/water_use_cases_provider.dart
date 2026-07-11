import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/repository_backend.dart';
import '../../../../core/database/drift/consistency/water_local_snapshot.dart';
import '../../../../core/database/drift/drift_database_providers.dart';
import '../../../../core/database/drift/cutover/water_cutover_service.dart';
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
  final storage = ref.watch(localStorageServiceProvider);
  Future<WaterCutoverService> cutoverService() async => WaterCutoverService(
    database: await ref.read(appDatabaseProvider.future),
    storage: storage,
  );
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
    ensureCutover: () async {
      if (userId == null) return;
      await (await cutoverService()).attempt(userId);
    },
    hasCutoverMirror: () {
      if (userId == null) return false;
      return WaterCutoverService.isCompletedMirrorFor(storage, userId);
    },
  );
});

final waterUseCasesProvider = Provider(
  (ref) => WaterUseCases(
    ref.watch(waterRepositoryProvider),
    ref.read(clockServiceProvider),
  ),
);
