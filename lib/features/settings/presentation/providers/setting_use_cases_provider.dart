import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/repository_backend.dart';
import '../../../../core/services/service_providers.dart';
import '../../data/datasources/local_settings_datasource.dart';
import '../../data/repositories/fake_setting_repository.dart';
import '../../data/repositories/local_settings_repository.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/use_cases.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return switch (ref.watch(repositoryBackendProvider)) {
    RepositoryBackend.fake => FakeSettingsRepository(),
    RepositoryBackend.local => LocalSettingsRepository(
      LocalSettingsDatasource(
        database: ref.watch(localDatabaseProvider),
        clock: ref.watch(clockServiceProvider),
      ),
    ),
    RepositoryBackend.supabase => throw UnsupportedError(
      'Settings Supabase repository will be enabled in the Supabase integration step.',
    ),
  };
});

final settingsUseCasesProvider = Provider<SettingsUseCases>((ref) {
  return SettingsUseCases(ref.read(settingsRepositoryProvider));
});
