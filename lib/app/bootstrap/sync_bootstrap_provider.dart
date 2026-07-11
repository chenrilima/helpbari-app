import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/sync/sync.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';

final syncBootstrapProvider = Provider<SyncBootstrapCoordinator>((ref) {
  final coordinator = SyncBootstrapCoordinator(ref);
  coordinator.initialize();
  return coordinator;
});

class SyncBootstrapCoordinator {
  SyncBootstrapCoordinator(this._ref);

  final Ref _ref;
  final Map<String, Future<void>> _initialSyncs = {};
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    _ref.listen(authSessionProvider, (previous, next) {
      if (next == null) {
        _initialSyncs.clear();
        return;
      }
      unawaited(_ensureInitialSync(next.id).catchError((_) {}));
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
    } catch (_) {
      // Sync errors are represented by SyncResult; bootstrap must remain usable.
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
    } catch (_) {
      // Manual retry preserves the offline-first UI on infrastructure errors.
    }
  }

  void onResumed() {
    final userId = _ref.read(authSessionProvider)?.id;
    if (userId != null) unawaited(retry());
  }
}
