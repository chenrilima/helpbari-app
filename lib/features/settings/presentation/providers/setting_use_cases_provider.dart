import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/repository_backend.dart';
import '../../../../core/database/drift/drift_database_providers.dart';
import '../../../../core/database/drift/migrations/settings_legacy_service.dart';
import '../../../../core/services/service_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/local_settings_datasource.dart';
import '../../data/datasources/drift_settings_local_datasource.dart';
import '../../data/repositories/drift_settings_repository.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/use_cases.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  ref.watch(repositoryBackendProvider);
  final userId =
      ref.watch(authSessionProvider)?.id ??
      SettingsLegacyService.anonymousUserId;
  final storage = ref.watch(localStorageServiceProvider);
  Future<SettingsLegacyService> legacy() async => SettingsLegacyService(
    database: await ref.read(appDatabaseProvider.future),
    storage: storage,
  );
  return DriftSettingsRepository(
    datasource: () async {
      if (!ref.read(driftAvailableProvider)) {
        throw StateError('Drift unavailable');
      }
      final database = await ref.read(appDatabaseProvider.future);
      return DriftSettingsLocalDatasource(
        dao: database.settingsDao,
        clock: ref.read(clockServiceProvider),
        userId: userId,
      );
    },
    fallback: LocalSettingsDatasource(
      database: ref.watch(localDatabaseProvider),
      clock: ref.watch(clockServiceProvider),
    ),
    legacy: legacy,
    userId: userId,
    logger: ref.watch(loggerServiceProvider),
    storage: storage,
  );
});

final settingsUseCasesProvider = Provider<SettingsUseCases>((ref) {
  return SettingsUseCases(ref.read(settingsRepositoryProvider));
});

final dailyWaterGoalProvider = FutureProvider<int>((ref) async {
  final settings = await ref.read(settingsUseCasesProvider).getSettings();
  return settings.dailyWaterGoalMl;
});
