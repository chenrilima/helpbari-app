import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/repository_backend.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../core/database/drift/drift_database_providers.dart';
import '../../../../core/database/drift/cutover/weight_cutover_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/drift_weight_local_datasource.dart';
import '../../data/datasources/local_weight_datasource.dart';
import '../../data/repositories/drift_primary_weight_repository.dart';
import '../../domain/repositories/repositories.dart';

final weightRepositoryProvider = Provider<WeightRepository>((ref) {
  ref.watch(repositoryBackendProvider);
  final userId = ref.watch(authSessionProvider)?.id;
  final effectiveUserId = userId ?? anonymousWeightUserId;
  final storage = ref.watch(localStorageServiceProvider);
  return DriftPrimaryWeightRepository(
    drift: () async => DriftWeightLocalDatasource(
      dao: (await ref.read(appDatabaseProvider.future)).weightDao,
      clock: ref.read(clockServiceProvider),
      userId: effectiveUserId,
    ),
    fallback: LocalWeightDatasource(
      database: ref.watch(localDatabaseProvider),
      clock: ref.watch(clockServiceProvider),
    ),
    logger: ref.watch(loggerServiceProvider),
    ensureCutover: () async {
      if (userId != null) {
        await WeightCutoverService(
          database: await ref.read(appDatabaseProvider.future),
          storage: storage,
        ).attempt(userId);
      }
    },
    hasCutoverMirror: () =>
        userId != null &&
        WeightCutoverService.isCompletedMirrorFor(storage, userId),
  );
});
