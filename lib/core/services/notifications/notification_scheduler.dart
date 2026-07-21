import 'dart:async';

import '../clock_service.dart';
import '../logger_service.dart';
import 'local_notification_payload.dart';
import 'local_notification_schedule.dart';
import 'local_notification_service.dart';
import 'notification_scheduler_state.dart';

class NotificationScheduler {
  NotificationScheduler({
    required LocalNotificationService notifications,
    required ClockService clock,
    required LoggerService logger,
    this.maxRetries = 2,
  }) : _notifications = notifications,
       _clock = clock,
       _logger = logger;

  final LocalNotificationService _notifications;
  final ClockService _clock;
  final LoggerService _logger;
  final int maxRetries;
  NotificationSchedulerState _state = const NotificationSchedulerState();
  final StreamController<NotificationSchedulerState> _states =
      StreamController<NotificationSchedulerState>.broadcast();

  NotificationSchedulerState get state => _state;
  Stream<NotificationSchedulerState> get states => _states.stream;
  Stream<LocalNotificationPayload> get taps => _notifications.taps.where(
    (payload) => _state.userId == null || payload.userId == _state.userId,
  );

  Future<bool> requestPermissions() => _notifications.requestPermissions();

  Future<void> schedule(LocalNotificationSchedule schedule) async {
    _requireCurrentUser(schedule.payload.userId);
    await _retry(() => _notifications.update(schedule));
    await _refreshScheduledCount();
  }

  Future<void> cancel(LocalNotificationPayload payload) async {
    if (payload.userId != _state.userId) return;
    await _retry(() => _notifications.cancelPayload(payload));
    await _refreshScheduledCount();
  }

  Future<void> cancelKey(String userId, String key) async {
    if (userId != _state.userId) return;
    await _retry(() => _notifications.cancel(key));
    await _refreshScheduledCount();
  }

  Future<void> restore({
    required String userId,
    required Iterable<LocalNotificationSchedule> schedules,
  }) async {
    await activateUser(userId);
    final unique = <String, LocalNotificationSchedule>{
      for (final schedule in schedules)
        if (schedule.payload.userId == userId) schedule.key: schedule,
    };
    var failures = _state.failures;
    if (_state.permission == NotificationPermissionState.granted) {
      for (final schedule in unique.values) {
        try {
          await _retry(() => _notifications.update(schedule));
        } catch (_) {
          failures++;
        }
      }
    }
    _setState(
      NotificationSchedulerState(
        scheduled: await _notifications.pendingCount(),
        failures: failures,
        lastRestoreAt: _clock.now(),
        permission: _state.permission,
        timeZone: _state.timeZone,
        userId: userId,
      ),
    );
  }

  Future<void> activateUser(String userId) async {
    await _notifications.initialize();
    if (_state.userId != null && _state.userId != userId) {
      await _notifications.cancelAll();
    }
    _setState(
      NotificationSchedulerState(
        scheduled: await _notifications.pendingCount(),
        failures: 0,
        permission: await _notifications.permissionState(),
        timeZone: await _notifications.localTimeZoneName(),
        userId: userId,
      ),
    );
  }

  Future<void> clearUser() async {
    await _notifications.cancelAll();
    _setState(const NotificationSchedulerState());
  }

  Future<void> _retry(Future<void> Function() operation) async {
    Object? lastError;
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        await operation();
        return;
      } catch (error) {
        lastError = error;
      }
    }
    _setState(
      NotificationSchedulerState(
        scheduled: _state.scheduled,
        failures: _state.failures + 1,
        lastRestoreAt: _state.lastRestoreAt,
        permission: _state.permission,
        timeZone: _state.timeZone,
        userId: _state.userId,
      ),
    );
    _logger.warning('Local notification operation failed after retries.');
    throw StateError(
      'Local notification operation failed: ${lastError.runtimeType}',
    );
  }

  void _requireCurrentUser(String userId) {
    if (_state.userId != userId) {
      throw StateError('Notification user is not active.');
    }
  }

  Future<void> _refreshScheduledCount() async {
    _setState(
      NotificationSchedulerState(
        scheduled: await _notifications.pendingCount(),
        failures: _state.failures,
        lastRestoreAt: _state.lastRestoreAt,
        permission: await _notifications.permissionState(),
        timeZone: await _notifications.localTimeZoneName(),
        userId: _state.userId,
      ),
    );
  }

  void _setState(NotificationSchedulerState value) {
    _state = value;
    _states.add(value);
  }

  Future<void> dispose() => _states.close();
}
