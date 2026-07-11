import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/service_providers.dart';
import '../database/drift/drift_database_providers.dart';
import '../supabase/database/supabase_database_provider.dart';
import '../supabase/supabase_client_provider.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/charts/presentation/providers/chart_series_providers.dart';
import '../../features/home/presentation/providers/home_view_model_provider.dart';
import '../../features/water/data/datasources/drift_water_local_datasource.dart';
import '../../features/water/data/datasources/water_supabase_datasource.dart';
import '../../features/water/data/repositories/water_sync_repository.dart';
import '../../features/water/presentation/providers/water_view_model_provider.dart';
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
    await ref.read(waterViewModelProvider.notifier).loadHistory();
    ref.invalidate(homeViewModelProvider);
    ref.invalidate(waterChartSeriesProvider);
    ref.invalidate(healthScoreChartSeriesProvider);
  };
});

final syncManagerProvider = NotifierProvider<SyncManager, SyncState>(
  SyncManager.new,
);
