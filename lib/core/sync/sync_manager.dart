import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sync_engine.dart';
import 'sync_providers.dart';
import 'sync_state.dart';
import 'sync_state_repository.dart';
import 'syncable_repository.dart';

class SyncManager extends Notifier<SyncState> {
  late final SyncEngine _engine;
  late final SyncStateRepository _stateRepository;
  late final List<SyncableRepository> _repositories;
  late final String _appVersion;
  late final String? _userId;

  @override
  SyncState build() {
    _engine = ref.read(syncEngineProvider);
    _stateRepository = ref.read(syncStateRepositoryProvider);
    _repositories = ref.watch(syncableRepositoriesProvider);
    _appVersion = ref.watch(syncAppVersionProvider);
    _userId = ref.watch(syncUserIdProvider);

    return const SyncState();
  }

  Future<void> loadState() async {
    state = await _stateRepository.ensureState(
      appVersion: _appVersion,
      userId: _userId,
    );
  }

  Future<void> syncNow() async {
    if (state.isSyncing) return;

    state = state.copyWith(phase: SyncPhase.syncing, clearError: true);

    final result = await _engine.sync(
      repositories: _repositories,
      appVersion: _appVersion,
      userId: _userId,
    );
    final persisted = await _stateRepository.getState();

    state = persisted.copyWith(
      phase: result.isSuccess ? SyncPhase.success : SyncPhase.failure,
      lastResult: result,
      errorMessage: result.isSuccess ? null : result.errors.first.message,
      clearError: result.isSuccess,
    );
  }
}
