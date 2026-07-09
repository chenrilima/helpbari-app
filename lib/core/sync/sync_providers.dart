import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/service_providers.dart';
import 'sync_engine.dart';
import 'sync_manager.dart';
import 'sync_state.dart';
import 'sync_state_repository.dart';
import 'syncable_repository.dart';

final syncableRepositoriesProvider = Provider<List<SyncableRepository>>((ref) {
  return const [];
});

final syncAppVersionProvider = Provider<String>((ref) {
  return 'unknown';
});

final syncUserIdProvider = Provider<String?>((ref) {
  return null;
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
