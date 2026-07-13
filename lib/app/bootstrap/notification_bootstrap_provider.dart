import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sync_bootstrap_provider.dart';
import '../../core/services/service_providers.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/settings/presentation/providers/setting_use_cases_provider.dart';
import '../../features/settings/presentation/providers/settings_reminder_sync_provider.dart';

final notificationBootstrapProvider =
    Provider<NotificationBootstrapCoordinator>((ref) {
      final coordinator = NotificationBootstrapCoordinator(ref)..initialize();
      return coordinator;
    });

class NotificationBootstrapCoordinator {
  NotificationBootstrapCoordinator(this._ref);

  final Ref _ref;
  Future<void> _queue = Future<void>.value();
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    _ref.listen(authSessionProvider, (previous, next) {
      _enqueue(() async {
        final scheduler = _ref.read(notificationSchedulerProvider);
        if (next == null) {
          await scheduler.clearUser();
          return;
        }
        if (previous?.id != next.id) {
          await scheduler.clearUser();
        }
        await scheduler.requestPermissions();
        await _restore(next.id);
      });
    }, fireImmediately: true);
  }

  void onResumed() {
    final userId = _ref.read(authSessionProvider)?.id;
    if (userId != null) _enqueue(() => _restore(userId));
  }

  void restoreAfterSync() {
    final userId = _ref.read(authSessionProvider)?.id;
    if (userId != null) _enqueue(() => _restore(userId));
  }

  Future<void> _restore(String userId) async {
    if (_ref.read(authSessionProvider)?.id != userId) return;
    await _ref.read(syncBootstrapProvider).waitForInitialSync(userId);
    if (_ref.read(authSessionProvider)?.id != userId) return;
    final settings = await _ref.read(settingsUseCasesProvider).getSettings();
    if (_ref.read(authSessionProvider)?.id != userId) return;
    await _ref.read(settingsReminderSyncServiceProvider).restore(settings);
  }

  void _enqueue(Future<void> Function() operation) {
    _queue = _queue.then((_) => operation()).catchError((_) {});
  }
}
