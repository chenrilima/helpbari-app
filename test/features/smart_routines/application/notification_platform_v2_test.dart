import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/services/clock_service.dart';
import 'package:helpbari/core/services/logger_service.dart';
import 'package:helpbari/core/services/notifications/notifications.dart';
import 'package:helpbari/features/smart_routines/application/routine_notification_projection.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'background action store is durable, deduplicated and user scoped',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final store = BackgroundNotificationActionStore(preferences);
      final action = BackgroundNotificationAction(
        actionId: 'delivery-1',
        payload: const LocalNotificationPayload(
          source: NotificationSource.smartRoutineOccurrence,
          entityId: 'occurrence-a',
          userId: 'user-a',
          action: 'taken',
        ),
        receivedAtUtc: DateTime.utc(2026, 7, 21, 12),
      );

      await store.enqueue(action);
      await store.enqueue(action);

      expect(store.forUser('user-a'), hasLength(1));
      expect(store.forUser('user-b'), isEmpty);
      await store.remove(['delivery-1']);
      expect(store.forUser('user-a'), isEmpty);
    },
  );

  test(
    'reconciler cancels the exact manifest key and keeps identical projection',
    () async {
      final notifications = _Notifications();
      final scheduler = NotificationScheduler(
        notifications: notifications,
        clock: const _Clock(),
        logger: const _Logger(),
      );
      await scheduler.restore(userId: 'user-a', schedules: const []);
      final manifest = _Manifest();
      final reconciler = NotificationProjectionReconciler(
        manifest: manifest,
        scheduler: scheduler,
      );
      final now = DateTime.utc(2026, 7, 21, 12);
      final projection = RoutineNotificationProjection(
        occurrenceId: 'occurrence-a',
        scheduleAtUtc: now.add(const Duration(hours: 1)),
        userId: 'user-a',
        actions: const {RoutineNotificationAction.taken},
      );

      await reconciler.reconcile(
        userId: 'user-a',
        desired: [projection],
        now: now,
      );
      expect(notifications.scheduledKeys, hasLength(1));
      await reconciler.reconcile(
        userId: 'user-a',
        desired: [projection],
        now: now,
      );
      expect(notifications.scheduledKeys, hasLength(1));
      final manifestKey = manifest.values.values.single.key;

      await reconciler.reconcile(userId: 'user-a', desired: const [], now: now);

      expect(notifications.canceledKeys, contains(manifestKey));
      expect(manifest.values, isEmpty);
    },
  );

  test('remind later schedules snooze without creating adherence', () async {
    final notifications = _Notifications();
    final scheduler = NotificationScheduler(
      notifications: notifications,
      clock: const _Clock(),
      logger: const _Logger(),
    );
    await scheduler.activateUser('user-a');
    final inbox = _Inbox(
      NotificationActionEnvelope(
        actionId: 'delivery-a',
        userId: 'user-a',
        occurrenceId: 'occurrence-a',
        action: RoutineNotificationActionType.remindLater,
        occurredAtUtc: DateTime.utc(2026, 7, 21, 12),
        receivedAtUtc: DateTime.utc(2026, 7, 21, 12),
      ),
    );
    final commands = _Commands();

    await NotificationActionHandler(
      inbox: inbox,
      commands: commands,
      scheduler: scheduler,
      manifest: _Manifest(),
    ).process('user-a');

    expect(commands.calls, 0);
    expect(notifications.scheduledKeys.single, contains(':snooze:delivery-a'));
    expect(inbox.completed, isTrue);
  });
}

class _Inbox implements NotificationActionInbox {
  _Inbox(this.value);
  final NotificationActionEnvelope value;
  bool completed = false;

  @override
  Future<void> complete(String userId, String actionId) async =>
      completed = true;
  @override
  Future<void> fail(String userId, String actionId, String code) async {}
  @override
  Future<List<NotificationActionEnvelope>> pending(String userId) async =>
      completed ? const [] : [value];
  @override
  Future<bool> receive(NotificationActionEnvelope envelope) async => true;
}

class _Commands implements RoutineAdherenceCommandPort {
  int calls = 0;
  @override
  Future<void> markOccurrence({
    required String userId,
    required String occurrenceId,
    required String actionId,
    required RoutineNotificationActionType action,
    required DateTime occurredAtUtc,
  }) async => calls++;
}

class _Manifest implements NotificationManifestRepository {
  final Map<String, NotificationManifestEntry> values = {};

  @override
  Future<void> clear(String userId) async =>
      values.removeWhere((_, value) => value.userId == userId);

  @override
  Future<List<NotificationManifestEntry>> entries(String userId) async =>
      values.values.where((value) => value.userId == userId).toList();

  @override
  Future<void> remove(String userId, String key) async => values.remove(key);

  @override
  Future<void> save(NotificationManifestEntry entry) async =>
      values[entry.key] = entry;
}

class _Notifications implements LocalNotificationService {
  final Set<String> scheduledKeys = {};
  final Set<String> canceledKeys = {};

  @override
  Future<void> cancel(String key) async {
    canceledKeys.add(key);
    scheduledKeys.remove(key);
  }

  @override
  Future<void> cancelAll() async => scheduledKeys.clear();

  @override
  Future<void> cancelPayload(LocalNotificationPayload payload) async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<String> localTimeZoneName() async => 'UTC';

  @override
  Future<int> pendingCount() async => scheduledKeys.length;

  @override
  Future<NotificationPermissionState> permissionState() async =>
      NotificationPermissionState.granted;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> reschedule(Iterable<LocalNotificationSchedule> schedules) async {
    for (final schedule in schedules) {
      await update(schedule);
    }
  }

  @override
  Future<void> scheduleOnce(LocalNotificationSchedule schedule) async =>
      scheduledKeys.add(schedule.key);

  @override
  Future<void> scheduleRecurring(LocalNotificationSchedule schedule) async =>
      scheduledKeys.add(schedule.key);

  @override
  Stream<LocalNotificationPayload> get taps => const Stream.empty();

  @override
  Future<void> update(LocalNotificationSchedule schedule) async =>
      scheduledKeys.add(schedule.key);
}

class _Clock implements ClockService {
  const _Clock();
  @override
  DateTime now() => DateTime.utc(2026, 7, 21, 12);
}

class _Logger implements LoggerService {
  const _Logger();
  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {}
  @override
  void info(String message) {}
  @override
  void warning(String message) {}
}
