import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sync_bootstrap_provider.dart';
import '../../core/services/service_providers.dart';
import '../../core/services/notifications/app_local_notification_service.dart';
import '../../core/sync/sync.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/settings/presentation/providers/setting_use_cases_provider.dart';
import '../../features/settings/presentation/providers/settings_reminder_sync_provider.dart';
import '../../features/settings/application/notification_preference_projection_service.dart';
import '../../features/appointments/presentation/providers/appointment_use_cases_provider.dart';
import '../../features/smart_routines/application/notification_platform.dart';
import '../../features/smart_routines/presentation/providers/unified_treatment_providers.dart';

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
          if (previous != null) {
            await (await _ref.read(
              notificationPlatformRepositoryProvider.future,
            )).clear(previous.id);
          }
          await scheduler.clearUser();
          return;
        }
        if (previous != null && previous.id != next.id) {
          await (await _ref.read(
            notificationPlatformRepositoryProvider.future,
          )).clear(previous.id);
          await scheduler.clearUser();
        }
        await _restore(next.id);
      });
    }, fireImmediately: true);
    _ref.listen(syncManagerProvider, (previous, next) {
      if (next.phase != SyncPhase.syncing &&
          next.lastSyncAt != null &&
          next.lastSyncAt != previous?.lastSyncAt) {
        restoreAfterSync();
      }
    });
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
    await _importBackgroundActions(userId);
    final settings = await _ref.read(settingsUseCasesProvider).getSettings();
    if (_ref.read(authSessionProvider)?.id != userId) return;
    await _ref.read(settingsReminderSyncServiceProvider).restore(settings);
    final now = _ref.read(clockServiceProvider).now().toUtc();
    final occurrenceWindow = await _ref.read(
      occurrenceWindowServiceProvider.future,
    );
    final projections = await occurrenceWindow.materializeAndProject(
      fromUtc: now.subtract(const Duration(hours: 12)),
      untilUtc: now.add(const Duration(days: 7)),
    );
    final preferenceProjections =
        const NotificationPreferenceProjectionService().project(
          userId: userId,
          preferences: settings.effectiveNotificationPreferences,
          nowUtc: now,
          appointments: await _ref.read(appointmentUseCasesProvider).getAll(),
        );
    await _ref
        .read(notificationV2ReconcilerProvider.future)
        .then(
          (reconciler) => reconciler.reconcile(
            userId: userId,
            desired: [...projections, ...preferenceProjections],
            now: now,
            preferences: settings.effectiveNotificationPreferences,
          ),
        );
    await _ref
        .read(notificationActionHandlerProvider.future)
        .then((handler) => handler.process(userId));
  }

  Future<void> _importBackgroundActions(String userId) async {
    final store = BackgroundNotificationActionStore(
      _ref.read(sharedPreferencesProvider),
    );
    final actions = store.forUser(userId);
    if (actions.isEmpty) return;
    final repository = await _ref.read(
      notificationPlatformRepositoryProvider.future,
    );
    final imported = <String>[];
    for (final action in actions) {
      final type = RoutineNotificationActionType.values
          .where((value) => value.name == action.payload.action)
          .firstOrNull;
      if (type == null) continue;
      await repository.receive(
        NotificationActionEnvelope(
          actionId: action.actionId,
          userId: userId,
          occurrenceId: action.payload.entityId,
          action: type,
          occurredAtUtc: action.receivedAtUtc,
          receivedAtUtc: action.receivedAtUtc,
        ),
      );
      imported.add(action.actionId);
    }
    await store.remove(imported);
  }

  void _enqueue(Future<void> Function() operation) {
    _queue = _queue.then((_) => operation()).catchError((_) {});
  }
}
