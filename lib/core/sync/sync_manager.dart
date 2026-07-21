import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logger/app_logger.dart';
import '../supabase/supabase_client_provider.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import 'sync_engine.dart';
import 'sync_providers.dart';
import 'sync_result.dart';
import 'sync_session.dart';
import 'sync_state.dart';
import 'sync_state_repository.dart';

class SyncManager extends Notifier<SyncState> {
  late final SyncEngine _engine;
  late final SyncStateRepository _stateRepository;
  late final String _appVersion;
  Future<SyncResult?>? _activeSync;
  int? _activeGeneration;

  @override
  SyncState build() {
    _engine = ref.read(syncEngineProvider);
    _stateRepository = ref.read(syncStateRepositoryProvider);
    _appVersion = ref.read(syncAppVersionProvider);
    ref.read(syncSessionRegistryProvider);

    return const SyncState();
  }

  Future<void> loadState() async {
    final userId = ref.read(syncUserIdProvider);
    if (userId == null) return;
    final session = ref.read(syncSessionRegistryProvider).capture(userId);
    final restored = await _stateRepository.ensureState(
      appVersion: _appVersion,
      userId: userId,
    );
    session.ensureCurrent();
    state = restored;
  }

  Future<SyncResult?> syncNow() {
    final userId = ref.read(syncUserIdProvider);
    if (userId == null) return Future<SyncResult?>.value();
    final session = ref.read(syncSessionRegistryProvider).capture(userId);
    final active = _activeSync;
    if (active != null && _activeGeneration == session.generation) {
      return active;
    }
    final run = active == null
        ? _runSync(session)
        : active.then(
            (_) => _runSync(session),
            onError: (_) => _runSync(session),
          );
    _activeGeneration = session.generation;
    _activeSync = run;
    return run;
  }

  Future<SyncResult?> _runSync(SyncSessionToken session) async {
    try {
      return await _performSync(session);
    } on SyncSessionRevokedException {
      return null;
    } finally {
      if (_activeGeneration == session.generation) {
        _activeSync = null;
        _activeGeneration = null;
      }
    }
  }

  Future<SyncResult?> _performSync(SyncSessionToken session) async {
    session.ensureCurrent();
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
      userId: session.userId,
      session: session,
    );
    session.ensureCurrent();
    final persisted = await _stateRepository.getState();
    session.ensureCurrent();

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
      errorMessage: result.isSuccess
          ? null
          : 'Não foi possível sincronizar todos os dados.',
      clearError: result.isSuccess,
    );
    session.ensureCurrent();

    // A pull may have committed local data even when another repository failed.
    // Always reload Drift consumers after a completed engine pass.
    await ref.read(syncDataRefreshProvider)(result);
    session.ensureCurrent();

    if (result.isSuccess) {
      AppLogger.info(
        'Sync concluído: ${result.repositoriesProcessed} repositório(s), '
        '${result.pushed} enviados, ${result.pulled} recebidos.',
      );
    } else {
      for (final error in result.errors) {
        AppLogger.error(
          'Sync ${error.repositoryKey}/${error.operation} falhou '
          '(${error.cause.runtimeType}).',
          stackTrace: error.stackTrace,
        );
      }
    }

    return result;
  }
}
