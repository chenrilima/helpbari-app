import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/services/services.dart';

void main() {
  test('stable key includes user, feature and entity', () {
    expect(
      notificationKey('user-a', NotificationSource.vitamin, 'vitamin-1'),
      'user-a:vitamin:vitamin-1',
    );
    expect(
      stableNotificationId('user-a:vitamin:vitamin-1'),
      stableNotificationId('user-a:vitamin:vitamin-1'),
    );
    expect(
      stableNotificationId('user-a:vitamin:vitamin-1'),
      isNot(stableNotificationId('user-b:vitamin:vitamin-1')),
    );
  });

  test('payload is typed, user scoped and rejects unknown sources', () {
    const payload = LocalNotificationPayload(
      source: NotificationSource.medication,
      entityId: 'med-1',
      userId: 'user-a',
    );
    expect(LocalNotificationPayload.decode(payload.encode())?.userId, 'user-a');
    expect(
      LocalNotificationPayload.decode(
        '{"source":"unknown","entityId":"one","userId":"user-a"}',
      ),
      isNull,
    );
  });

  test(
    'multiple restores deduplicate and replace previous user schedules',
    () async {
      final plugin = _Notifications();
      final scheduler = _scheduler(plugin);
      final schedule = _schedule('user-a', 'one');

      await scheduler.restore(
        userId: 'user-a',
        schedules: [schedule, schedule],
      );
      await scheduler.restore(userId: 'user-a', schedules: [schedule]);

      expect(plugin.pending.keys, [schedule.key]);
      expect(scheduler.state.scheduled, 1);
      expect(scheduler.state.failures, 0);

      await scheduler.restore(
        userId: 'user-b',
        schedules: [_schedule('user-b', 'two')],
      );
      expect(plugin.pending.keys, ['user-b:vitamin:two']);
      expect(scheduler.state.userId, 'user-b');
    },
  );

  test('logout removes all schedules and filters another user tap', () async {
    final plugin = _Notifications();
    final scheduler = _scheduler(plugin);
    await scheduler.restore(
      userId: 'user-a',
      schedules: [_schedule('user-a', 'one')],
    );
    final received = <LocalNotificationPayload>[];
    final subscription = scheduler.taps.listen(received.add);
    plugin.controller.add(_payload('user-b', 'foreign'));
    plugin.controller.add(_payload('user-a', 'own'));
    await Future<void>.delayed(Duration.zero);

    expect(received.map((value) => value.entityId), ['own']);
    await scheduler.clearUser();
    expect(plugin.pending, isEmpty);
    expect(scheduler.state.userId, isNull);
    await subscription.cancel();
  });

  test('denied permission leaves no schedule and exposes status', () async {
    final plugin = _Notifications()
      ..permission = NotificationPermissionState.denied;
    final scheduler = _scheduler(plugin);

    await scheduler.restore(
      userId: 'user-a',
      schedules: [_schedule('user-a', 'one')],
    );

    expect(plugin.pending, isEmpty);
    expect(scheduler.state.permission, NotificationPermissionState.denied);
  });

  test('plugin failure retries without leaking health data to logs', () async {
    final plugin = _Notifications()..failuresBeforeSuccess = 2;
    final logger = _Logger();
    final scheduler = NotificationScheduler(
      notifications: plugin,
      clock: const _Clock(),
      logger: logger,
      maxRetries: 2,
    );

    await scheduler.restore(
      userId: 'user-a',
      schedules: [_schedule('user-a', 'one')],
    );

    expect(plugin.attempts, 3);
    expect(plugin.pending, hasLength(1));
    expect(logger.messages.join(), isNot(contains('one')));
  });

  test(
    'daily schedule preserves local wall-clock for timezone restoration',
    () {
      final schedule = NotificationSchedules.dailyReminder(
        source: NotificationSource.vitamin,
        userId: 'user-a',
        entityId: 'one',
        title: 'title',
        body: 'body',
        hour: 8,
        minute: 30,
        now: DateTime(2026, 11, 1, 23),
      );
      expect(schedule.scheduledAt, DateTime(2026, 11, 1, 8, 30));
      expect(schedule.recurrence, LocalNotificationRecurrence.daily);
    },
  );
}

NotificationScheduler _scheduler(_Notifications notifications) =>
    NotificationScheduler(
      notifications: notifications,
      clock: const _Clock(),
      logger: _Logger(),
    );

LocalNotificationSchedule _schedule(String userId, String entityId) =>
    NotificationSchedules.dailyReminder(
      source: NotificationSource.vitamin,
      userId: userId,
      entityId: entityId,
      title: 'Lembrete',
      body: 'Registro diário',
      hour: 8,
      minute: 0,
      now: DateTime(2026, 7, 12),
    );

LocalNotificationPayload _payload(String userId, String entityId) =>
    LocalNotificationPayload(
      source: NotificationSource.vitamin,
      entityId: entityId,
      userId: userId,
    );

class _Notifications implements LocalNotificationService {
  final Map<String, LocalNotificationSchedule> pending = {};
  final StreamController<LocalNotificationPayload> controller =
      StreamController<LocalNotificationPayload>.broadcast();
  NotificationPermissionState permission = NotificationPermissionState.granted;
  int failuresBeforeSuccess = 0;
  int attempts = 0;

  @override
  Stream<LocalNotificationPayload> get taps => controller.stream;
  @override
  Future<void> cancel(String key) async => pending.remove(key);
  @override
  Future<void> cancelAll() async => pending.clear();
  @override
  Future<void> cancelPayload(LocalNotificationPayload payload) async =>
      pending.remove(
        notificationKey(payload.userId, payload.source, payload.entityId),
      );
  @override
  Future<void> initialize() async {}
  @override
  Future<String> localTimeZoneName() async => 'America/New_York';
  @override
  Future<int> pendingCount() async => pending.length;
  @override
  Future<NotificationPermissionState> permissionState() async => permission;
  @override
  Future<bool> requestPermissions() async =>
      permission == NotificationPermissionState.granted;
  @override
  Future<void> reschedule(Iterable<LocalNotificationSchedule> schedules) async {
    for (final schedule in schedules) {
      await update(schedule);
    }
  }

  @override
  Future<void> scheduleOnce(LocalNotificationSchedule schedule) =>
      update(schedule);
  @override
  Future<void> scheduleRecurring(LocalNotificationSchedule schedule) =>
      update(schedule);
  @override
  Future<void> update(LocalNotificationSchedule schedule) async {
    attempts++;
    if (failuresBeforeSuccess > 0) {
      failuresBeforeSuccess--;
      throw StateError('plugin');
    }
    pending[schedule.key] = schedule;
  }
}

class _Clock implements ClockService {
  const _Clock();
  @override
  DateTime now() => DateTime(2026, 7, 12, 12);
}

class _Logger implements LoggerService {
  final List<String> messages = [];
  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      messages.add(message);
  @override
  void info(String message) => messages.add(message);
  @override
  void warning(String message) => messages.add(message);
}
