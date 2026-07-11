import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/repository_backend.dart';
import '../../../../core/database/drift/cutover/profile_cutover_service.dart';
import '../../../../core/database/drift/drift_database_providers.dart';
import '../../../../core/services/service_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/drift_profile_local_datasource.dart';
import '../../data/datasources/local_profile_datasource.dart';
import '../../data/repositories/drift_primary_profile_repository.dart';
import '../../domain/repositories/repositories.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  ref.watch(repositoryBackendProvider);
  final userId = ref.watch(authSessionProvider)?.id;
  if (userId == null) {
    throw StateError('Profile requires an authenticated userId.');
  }
  final storage = ref.watch(localStorageServiceProvider);
  Future<ProfileCutoverService> cutover() async => ProfileCutoverService(
    database: await ref.read(appDatabaseProvider.future),
    storage: storage,
  );
  return DriftPrimaryProfileRepository(
    drift: () async {
      if (!ref.read(driftAvailableProvider)) {
        throw StateError('Drift unavailable');
      }
      final database = await ref.read(appDatabaseProvider.future);
      return DriftProfileLocalDatasource(
        dao: database.profileDao,
        clock: ref.read(clockServiceProvider),
        userId: userId,
      );
    },
    fallback: LocalProfileDatasource(
      database: ref.watch(localDatabaseProvider),
      clock: ref.watch(clockServiceProvider),
      userId: userId,
    ),
    ensureCutover: () async {
      await (await cutover()).attempt(userId);
    },
    hasCutoverMirror: () =>
        ProfileCutoverService.isCompletedMirrorFor(storage, userId),
  );
});
