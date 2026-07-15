import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logger/app_logger.dart';
import '../supabase/supabase_client_provider.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import 'sync_engine.dart';
import 'sync_providers.dart';
import 'sync_result.dart';
import 'sync_state.dart';
import 'sync_state_repository.dart';

class SyncManager extends Notifier<SyncState> {
  late final SyncEngine _engine;
  late final SyncStateRepository _stateRepository;
  late final String _appVersion;
  Future<SyncResult?>? _activeSync;

  @override
  SyncState build() {
    _engine = ref.read(syncEngineProvider);
    _stateRepository = ref.read(syncStateRepositoryProvider);
    _appVersion = ref.read(syncAppVersionProvider);

    return const SyncState();
  }

  Future<void> loadState() async {
    state = await _stateRepository.ensureState(
      appVersion: _appVersion,
      userId: ref.read(syncUserIdProvider),
    );
  }

  Future<SyncResult?> syncNow() => _activeSync ??= _runSync();

  Future<SyncResult?> _runSync() async {
    try {
      return await _performSync();
    } finally {
      _activeSync = null;
    }
  }

  Future<SyncResult?> _performSync() async {
    final user = ref.read(authSessionProvider);
    SyncPhase? unavailablePhase;
    if (user == null) {
      unavailablePhase = SyncPhase.unavailableNoUser;
    } else if (ref.read(supabaseClientProvider) == null) {
      unavailablePhase = SyncPhase.unavailableNoRemoteClient;
    }
    state = state.copyWith(phase: SyncPhase.syncing, clearError: true);

    final result = await _engine.sync(
      repositories: ref.read(syncableRepositoriesProvider),
      appVersion: _appVersion,
      userId: ref.read(syncUserIdProvider),
    );
    final persisted = await _stateRepository.getState();

    final phase = result.isSuccess
        ? SyncPhase.success
        : result.repositoriesProcessed == 0
        ? unavailablePhase ?? SyncPhase.skippedNoRepositories
        : result.pushed > 0 || result.pulled > 0
        ? SyncPhase.partialFailure
        : SyncPhase.failure;
    state = persisted.copyWith(
      phase: phase,
      lastResult: result,
      errorMessage: result.isSuccess ? null : result.errors.first.message,
      clearError: result.isSuccess,
    );

    // A pull may have committed local data even when another repository failed.
    // Always reload Drift consumers after a completed engine pass.
    await ref.read(syncDataRefreshProvider)();

    if (result.isSuccess) {
      AppLogger.info(
        'Sync concluído: ${result.repositoriesProcessed} repositório(s), '
        '${result.pushed} enviados, ${result.pulled} recebidos.',
      );
    } else {
      for (final error in result.errors) {
        AppLogger.error(
          'Sync ${error.repositoryKey}/${error.operation}: ${error.message}',
          error: error.cause,
          stackTrace: error.stackTrace,
        );
      }
    }

    return result;
  }
}
