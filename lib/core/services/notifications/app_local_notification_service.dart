import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../logger_service.dart';
import 'local_notification_payload.dart';
import 'local_notification_schedule.dart';
import 'local_notification_service.dart';
import 'notification_schedules.dart';

@pragma('vm:entry-point')
Future<void> localNotificationTapBackground(
  NotificationResponse response,
) async {
  DartPluginRegistrant.ensureInitialized();
  final payload = LocalNotificationPayload.decode(response.payload);
  final action = response.actionId;
  if (payload == null ||
      payload.source != NotificationSource.smartRoutineOccurrence ||
      action == null ||
      action.isEmpty ||
      action == 'open') {
    return;
  }
  final preferences = await SharedPreferences.getInstance();
  await BackgroundNotificationActionStore(preferences).enqueue(
    BackgroundNotificationAction(
      actionId: notificationActionId(payload, action, response.id),
      payload: payload.copyWith(action: action),
      receivedAtUtc: DateTime.now().toUtc(),
    ),
  );
}

String notificationActionId(
  LocalNotificationPayload payload,
  String action,
  int? notificationId,
) => '${payload.userId}:${payload.entityId}:$action:${notificationId ?? 0}';

class BackgroundNotificationAction {
  const BackgroundNotificationAction({
    required this.actionId,
    required this.payload,
    required this.receivedAtUtc,
  });

  final String actionId;
  final LocalNotificationPayload payload;
  final DateTime receivedAtUtc;

  Map<String, Object?> toJson() => {
    'actionId': actionId,
    'payload': payload.encode(),
    'receivedAtUtc': receivedAtUtc.toIso8601String(),
  };

  static BackgroundNotificationAction? fromJson(Object? value) {
    if (value is! Map<String, Object?>) return null;
    final actionId = value['actionId'];
    final payload = LocalNotificationPayload.decode(
      value['payload'] as String?,
    );
    final receivedAt = DateTime.tryParse(
      value['receivedAtUtc'] as String? ?? '',
    );
    if (actionId is! String || payload == null || receivedAt == null) {
      return null;
    }
    return BackgroundNotificationAction(
      actionId: actionId,
      payload: payload,
      receivedAtUtc: receivedAt.toUtc(),
    );
  }
}

class BackgroundNotificationActionStore {
  const BackgroundNotificationActionStore(this.preferences);

  static const storageKeyPrefix = 'notifications.v2.background_action.';
  final SharedPreferences preferences;

  Future<void> enqueue(BackgroundNotificationAction action) async {
    final key = _key(action.actionId);
    if (preferences.containsKey(key)) return;
    await preferences.setString(key, jsonEncode(action.toJson()));
  }

  List<BackgroundNotificationAction> forUser(String userId) =>
      _read().where((value) => value.payload.userId == userId).toList();

  Future<void> remove(Iterable<String> actionIds) async {
    for (final actionId in actionIds.toSet()) {
      await preferences.remove(_key(actionId));
    }
  }

  List<BackgroundNotificationAction> _read() {
    final result = <BackgroundNotificationAction>[];
    for (final key in preferences.getKeys().where(
      (value) => value.startsWith(storageKeyPrefix),
    )) {
      final encoded = preferences.getString(key);
      if (encoded == null) continue;
      try {
        final action = BackgroundNotificationAction.fromJson(
          jsonDecode(encoded),
        );
        if (action != null) result.add(action);
      } on FormatException {
        continue;
      }
    }
    return result;
  }

  String _key(String actionId) =>
      '$storageKeyPrefix${base64Url.encode(utf8.encode(actionId)).replaceAll('=', '')}';
}

class AppLocalNotificationService implements LocalNotificationService {
  AppLocalNotificationService({
    required LoggerService logger,
    FlutterLocalNotificationsPlugin? plugin,
  }) : _logger = logger,
       _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'helpbari_reminders';
  static const _channelName = 'Lembretes';
  static const _channelDescription =
      'Lembretes configurados pelo usuário no HelpBari.';

  final LoggerService _logger;
  final FlutterLocalNotificationsPlugin _plugin;
  final StreamController<LocalNotificationPayload> _taps =
      StreamController<LocalNotificationPayload>.broadcast();

  bool _initialized = false;
  String _localTimeZoneName = 'UTC';
  LocalNotificationPayload? _pendingLaunchPayload;

  @override
  Stream<LocalNotificationPayload> get taps async* {
    final pending = _pendingLaunchPayload;
    _pendingLaunchPayload = null;
    if (pending != null) yield pending;
    yield* _taps.stream;
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    timezone_data.initializeTimeZones();
    await _configureLocalTimeZone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: <DarwinNotificationCategory>[
        DarwinNotificationCategory(
          'helpbari_routine_occurrence',
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain('taken', 'Tomado'),
            DarwinNotificationAction.plain('skipped', 'Ignorar'),
            DarwinNotificationAction.plain('remindLater', 'Lembrar depois'),
          ],
        ),
      ],
    );
    final settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _handleTap,
      onDidReceiveBackgroundNotificationResponse:
          localNotificationTapBackground,
    );

    _initialized = true;
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final launchResponse = launch?.notificationResponse;
    if (launch?.didNotificationLaunchApp ?? false) {
      _emitPayload(launchResponse?.payload, retainForFirstListener: true);
    }
  }

  @override
  Future<bool> requestPermissions() async {
    await initialize();

    final status = await Permission.notification.request();
    final androidGranted =
        _platform != TargetPlatform.android || status.isGranted;

    if (_platform != TargetPlatform.iOS) {
      return androidGranted;
    }

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final iosGranted =
        await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;

    return androidGranted && iosGranted;
  }

  @override
  Future<NotificationPermissionState> permissionState() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return NotificationPermissionState.granted;
    if (status.isPermanentlyDenied) {
      return NotificationPermissionState.permanentlyDenied;
    }
    return NotificationPermissionState.denied;
  }

  @override
  Future<String> localTimeZoneName() async {
    await initialize();
    await _configureLocalTimeZone();
    return _localTimeZoneName;
  }

  @override
  Future<int> pendingCount() async {
    await initialize();
    return (await _plugin.pendingNotificationRequests()).length;
  }

  @override
  Future<void> scheduleOnce(LocalNotificationSchedule schedule) async {
    await _schedule(
      schedule.copyWithRecurrence(LocalNotificationRecurrence.none),
    );
  }

  @override
  Future<void> scheduleRecurring(LocalNotificationSchedule schedule) async {
    await _schedule(schedule);
  }

  @override
  Future<void> update(LocalNotificationSchedule schedule) async {
    await cancel(schedule.key);

    if (schedule.recurrence == LocalNotificationRecurrence.none) {
      await scheduleOnce(schedule);
      return;
    }

    await scheduleRecurring(schedule);
  }

  @override
  Future<void> reschedule(Iterable<LocalNotificationSchedule> schedules) async {
    for (final schedule in schedules) {
      await update(schedule);
    }
  }

  @override
  Future<void> cancel(String key) async {
    await initialize();
    await _plugin.cancel(id: stableNotificationId(key));
  }

  @override
  Future<void> cancelPayload(LocalNotificationPayload payload) {
    return cancel(
      notificationKey(payload.userId, payload.source, payload.entityId),
    );
  }

  @override
  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }

  Future<void> _schedule(LocalNotificationSchedule schedule) async {
    await initialize();

    final permission = await permissionState();
    if (permission != NotificationPermissionState.granted) {
      _logger.warning('Permissao de notificacao nao concedida.');
      return;
    }

    final scheduledDate = _nextScheduledDate(schedule);
    if (scheduledDate == null) return;

    await _plugin.zonedSchedule(
      id: schedule.notificationId,
      title: schedule.title,
      body: schedule.body,
      scheduledDate: scheduledDate,
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: _matchDateTimeComponents(schedule.recurrence),
      payload: schedule.payload.encode(),
    );
  }

  timezone.TZDateTime? _nextScheduledDate(LocalNotificationSchedule schedule) {
    final now = timezone.TZDateTime.now(timezone.local);
    var scheduled = timezone.TZDateTime.from(
      schedule.scheduledAt,
      timezone.local,
    );

    if (schedule.recurrence == LocalNotificationRecurrence.none) {
      return scheduled.isAfter(now) ? scheduled : null;
    }

    while (!scheduled.isAfter(now)) {
      if (schedule.recurrence == LocalNotificationRecurrence.weekly) {
        scheduled = scheduled.add(const Duration(days: 7));
        continue;
      }

      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  DateTimeComponents? _matchDateTimeComponents(
    LocalNotificationRecurrence recurrence,
  ) {
    return switch (recurrence) {
      LocalNotificationRecurrence.none => null,
      LocalNotificationRecurrence.daily => DateTimeComponents.time,
      LocalNotificationRecurrence.weekly => DateTimeComponents.dayOfWeekAndTime,
    };
  }

  NotificationDetails get _notificationDetails {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('taken', 'Tomado'),
        AndroidNotificationAction('skipped', 'Ignorar'),
        AndroidNotificationAction('remindLater', 'Lembrar depois'),
      ],
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'helpbari_routine_occurrence',
    );

    return const NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  void _handleTap(NotificationResponse response) {
    _emitPayload(
      response.payload,
      action: response.actionId,
      notificationId: response.id,
    );
  }

  void _emitPayload(
    String? encoded, {
    bool retainForFirstListener = false,
    String? action,
    int? notificationId,
  }) {
    final decoded = LocalNotificationPayload.decode(encoded);
    final payload = decoded == null || action == null || action.isEmpty
        ? decoded
        : decoded.copyWith(
            action: action,
            data: {
              ...decoded.data,
              'actionId': notificationActionId(decoded, action, notificationId),
            },
          );

    if (payload == null) {
      _logger.warning('Payload de notificacao invalido.');
      return;
    }

    _logger.info('Local notification opened (${payload.source.name}).');
    if (retainForFirstListener) {
      _pendingLaunchPayload = payload;
    } else {
      _taps.add(payload);
    }
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      final identifier = (await FlutterTimezone.getLocalTimezone()).identifier;
      timezone.setLocalLocation(timezone.getLocation(identifier));
      _localTimeZoneName = identifier;
    } catch (_) {
      _localTimeZoneName = 'UTC';
      timezone.setLocalLocation(timezone.UTC);
      _logger.warning('Unable to resolve device timezone; using UTC.');
    }
  }

  TargetPlatform get _platform => defaultTargetPlatform;
}

extension on LocalNotificationSchedule {
  LocalNotificationSchedule copyWithRecurrence(
    LocalNotificationRecurrence recurrence,
  ) {
    return LocalNotificationSchedule(
      key: key,
      title: title,
      body: body,
      scheduledAt: scheduledAt,
      payload: payload,
      recurrence: recurrence,
    );
  }
}
