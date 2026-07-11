import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/service_providers.dart';
import '../supabase/database/supabase_database_provider.dart';
import '../supabase/supabase_client_provider.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/water/data/datasources/local_water_datasource.dart';
import '../../features/water/data/datasources/water_supabase_datasource.dart';
import '../../features/water/data/repositories/water_sync_repository.dart';
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
      localDatasource: LocalWaterDatasource(
        database: ref.watch(localDatabaseProvider),
        clock: ref.watch(clockServiceProvider),
        userId: user.id,
      ),
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

final syncManagerProvider = NotifierProvider<SyncManager, SyncState>(
  SyncManager.new,
);
