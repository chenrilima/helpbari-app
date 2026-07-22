import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/sync/sync.dart';
import '../../core/logger/app_logger.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';

final syncBootstrapProvider = Provider<SyncBootstrapCoordinator>((ref) {
  final coordinator = SyncBootstrapCoordinator(ref);
  coordinator.initialize();
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

class SyncBootstrapCoordinator {
  SyncBootstrapCoordinator(this._ref);

  final Ref _ref;
  final Map<String, Future<void>> _initialSyncs = {};
  late final SyncConnectivityTrigger _connectivity;
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    _connectivity = SyncConnectivityTrigger(onRecovered: retry)
      ..listen(_ref.read(syncConnectivityChangesProvider));

    _ref.listen(authSessionProvider, (previous, next) {
      if (previous?.id != next?.id) _initialSyncs.clear();
      if (next == null) {
        return;
      }
      unawaited(
        _ensureInitialSync(next.id).catchError((
          Object error,
          StackTrace stack,
        ) {
          if (error is! SyncSessionRevokedException) {
            AppLogger.error(
              'Initial sync failed (${error.runtimeType}).',
              stackTrace: stack,
            );
          }
        }),
      );
    }, fireImmediately: true);
  }

  Future<void> waitForInitialSync(
    String userId, {
    Duration timeout = const Duration(seconds: 4),
    Future<void>? cancelled,
  }) async {
    final timedOut = Completer<void>();
    final timer = Timer(timeout, timedOut.complete);
    try {
      await Future.any([
        _ensureInitialSync(userId),
        timedOut.future,
        ?cancelled,
      ]);
    } on SyncSessionRevokedException {
      // Expected when authentication changes while bootstrap is running.
    } catch (error, stackTrace) {
      // Sync errors are represented by SyncResult; bootstrap must remain usable.
      AppLogger.error(
        'Initial sync wait failed (${error.runtimeType}).',
        stackTrace: stackTrace,
      );
    } finally {
      timer.cancel();
    }
  }

  Future<void> _ensureInitialSync(String userId) =>
      _initialSyncs.putIfAbsent(userId, () async {
        await _ref.read(syncManagerProvider.notifier).loadState();
        await _ref.read(syncManagerProvider.notifier).syncNow();
      });

  Future<void> retry() async {
    final userId = _ref.read(authSessionProvider)?.id;
    if (userId == null) return;
    try {
      await _ref.read(syncManagerProvider.notifier).syncNow();
    } catch (error, stackTrace) {
      // Manual retry preserves the offline-first UI on infrastructure errors.
      AppLogger.error(
        'Manual sync retry failed (${error.runtimeType}).',
        stackTrace: stackTrace,
      );
    }
  }

  void onResumed() {
    _connectivity.setForeground(true);
    final userId = _ref.read(authSessionProvider)?.id;
    if (userId != null) unawaited(retry());
  }

  void onBackgrounded() => _connectivity.setForeground(false);

  Future<void> dispose() => _connectivity.dispose();
}
