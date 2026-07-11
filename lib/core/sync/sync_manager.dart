import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logger/app_logger.dart';
import 'sync_engine.dart';
import 'sync_providers.dart';
import 'sync_result.dart';
import 'sync_state.dart';
import 'sync_state_repository.dart';

class SyncManager extends Notifier<SyncState> {
  late final SyncEngine _engine;
  late final SyncStateRepository _stateRepository;
  late final String _appVersion;

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

  Future<SyncResult?> syncNow() async {
    if (state.isSyncing) return state.lastResult;

    state = state.copyWith(phase: SyncPhase.syncing, clearError: true);

    final result = await _engine.sync(
      repositories: ref.read(syncableRepositoriesProvider),
      appVersion: _appVersion,
      userId: ref.read(syncUserIdProvider),
    );
    final persisted = await _stateRepository.getState();

    state = persisted.copyWith(
      phase: result.isSuccess ? SyncPhase.success : SyncPhase.failure,
      lastResult: result,
      errorMessage: result.isSuccess ? null : result.errors.first.message,
      clearError: result.isSuccess,
    );

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
