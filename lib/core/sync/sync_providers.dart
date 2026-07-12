import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/service_providers.dart';
import '../database/drift/drift_database_providers.dart';
import '../supabase/database/supabase_database_provider.dart';
import '../supabase/supabase_client_provider.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/charts/presentation/providers/chart_series_providers.dart';
import '../../features/home/presentation/providers/home_view_model_provider.dart';
import '../../features/settings/data/datasources/drift_settings_local_datasource.dart';
import '../../features/settings/data/datasources/settings_supabase_datasource.dart';
import '../../features/settings/data/repositories/settings_sync_repository.dart';
import '../../features/settings/presentation/providers/setting_use_cases_provider.dart';
import '../../features/settings/presentation/providers/setting_view_model_provider.dart';
import '../../features/settings/presentation/providers/settings_reminder_sync_provider.dart';
import '../../features/profile/data/datasources/drift_profile_local_datasource.dart';
import '../../features/profile/data/datasources/profile_supabase_datasource.dart';
import '../../features/profile/data/repositories/profile_sync_repository.dart';
import '../../features/profile/presentation/providers/profile_view_model_provider.dart';
import '../../features/medical_reports/presentation/providers/medical_report_providers.dart';
import '../../features/water/data/datasources/drift_water_local_datasource.dart';
import '../../features/water/data/datasources/water_supabase_datasource.dart';
import '../../features/water/data/repositories/water_sync_repository.dart';
import '../../features/water/presentation/providers/water_view_model_provider.dart';
import '../../features/weight/data/datasources/drift_weight_local_datasource.dart';
import '../../features/weight/data/datasources/weight_supabase_datasource.dart';
import '../../features/weight/data/repositories/weight_sync_repository.dart';
import '../../features/weight/presentation/providers/weight_view_model_provider.dart';
import '../../features/meals/data/datasources/drift_meal_local_datasource.dart';
import '../../features/meals/data/datasources/meal_supabase_datasource.dart';
import '../../features/meals/data/repositories/meal_sync_repository.dart';
import '../../features/meals/presentation/providers/meal_view_model_provider.dart';
import '../../features/meals/presentation/providers/meal_use_cases_provider.dart';
import '../../features/progress/presentation/providers/progress_view_model_provider.dart';
import '../../features/baria/presentation/providers/baria_view_model_provider.dart';
import 'sync_engine.dart';
import 'sync_manager.dart';
import 'sync_state.dart';
import 'sync_state_repository.dart';
import 'syncable_repository.dart';

final syncableRepositoriesProvider = Provider<List<SyncableRepository>>((ref) {
  final user = ref.watch(authSessionProvider);
  final supabaseClient = ref.watch(supabaseClientProvider);

  if (user == null || supabaseClient == null) return const [];

  return [
    ProfileSyncRepository(
      local: () async {
        if (!ref.read(driftAvailableProvider)) {
          throw StateError('Drift unavailable');
        }
        final database = await ref.read(appDatabaseProvider.future);
        return DriftProfileLocalDatasource(
          dao: database.profileDao,
          clock: ref.read(clockServiceProvider),
          userId: user.id,
        );
      },
      remote: ProfileSupabaseDatasource(ref.watch(supabaseDatabaseProvider)),
      userId: user.id,
    ),
    WaterSyncRepository(
      localDatasource: () async {
        if (!ref.read(driftAvailableProvider)) {
          throw StateError('Drift unavailable');
        }
        final database = await ref.read(appDatabaseProvider.future);
        return DriftWaterLocalDatasource(
          dao: database.waterDao,
          clock: ref.read(clockServiceProvider),
          userId: user.id,
        );
      },
      supabaseDatasource: WaterSupabaseDatasource(
        ref.watch(supabaseDatabaseProvider),
      ),
      userId: user.id,
    ),
    WeightSyncRepository(
      local: () async => DriftWeightLocalDatasource(
        dao: (await ref.read(appDatabaseProvider.future)).weightDao,
        clock: ref.read(clockServiceProvider),
        userId: user.id,
      ),
      remote: WeightSupabaseDatasource(ref.watch(supabaseDatabaseProvider)),
      userId: user.id,
    ),
    MealSyncRepository(
      local: () async => DriftMealLocalDatasource(
        dao: (await ref.read(appDatabaseProvider.future)).mealDao,
        clock: ref.read(clockServiceProvider),
        userId: user.id,
      ),
      remote: MealSupabaseDatasource(ref.watch(supabaseDatabaseProvider)),
      userId: user.id,
    ),
    SettingsSyncRepository(
      local: () async {
        if (!ref.read(driftAvailableProvider)) {
          throw StateError('Drift unavailable');
        }
        final database = await ref.read(appDatabaseProvider.future);
        return DriftSettingsLocalDatasource(
          dao: database.settingsDao,
          clock: ref.read(clockServiceProvider),
          userId: user.id,
        );
      },
      remote: SettingsSupabaseDatasource(ref.watch(supabaseDatabaseProvider)),
      userId: user.id,
      afterCommit: (dto) async {
        await ref
            .read(settingsReminderSyncServiceProvider)
            .applyAfterCommit(dto.toEntity());
      },
    ),
  ];
});

final syncAppVersionProvider = Provider<String>((ref) {
  return 'unknown';
});

final syncUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authSessionProvider)?.id;
});

final syncStateRepositoryProvider = Provider<SyncStateRepository>((ref) {
  return LocalSyncStateRepository(
    storage: ref.watch(localStorageServiceProvider),
    uuidService: ref.watch(uuidServiceProvider),
  );
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(
    stateRepository: ref.watch(syncStateRepositoryProvider),
    clock: ref.watch(clockServiceProvider),
  );
});

final syncDataRefreshProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    ref.invalidate(settingsUseCasesProvider);
    ref.invalidate(dailyWaterGoalProvider);
    ref.invalidate(homeViewModelProvider);
    ref.invalidate(waterViewModelProvider);
    ref.invalidate(weightViewModelProvider);
    ref.invalidate(mealUseCasesProvider);
    ref.invalidate(mealViewModelProvider);
    ref.invalidate(weightChartSeriesProvider);
    ref.invalidate(progressViewModelProvider);
    ref.invalidate(waterChartSeriesProvider);
    ref.invalidate(healthScoreChartSeriesProvider);
    ref.invalidate(medicalReportUseCasesProvider);
    ref.invalidate(medicalReportViewModelProvider);
    ref.invalidate(bariaViewModelProvider);
    ref.invalidate(profileViewModelProvider);
    await ref.read(settingsViewModelProvider.notifier).loadSettings();
    await Future.wait([
      ref.read(waterViewModelProvider.notifier).loadHistory(),
      ref.read(weightViewModelProvider.notifier).loadHistory(),
      ref.read(mealViewModelProvider.notifier).loadMeals(),
      ref.read(homeViewModelProvider.notifier).loadHome(),
      ref.read(bariaViewModelProvider.notifier).loadDailyInsight(),
      ref.read(profileViewModelProvider.notifier).loadProfile(),
    ]);
  };
});

final syncManagerProvider = NotifierProvider<SyncManager, SyncState>(
  SyncManager.new,
);
