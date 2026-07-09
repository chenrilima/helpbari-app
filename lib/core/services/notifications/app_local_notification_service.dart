import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../logger_service.dart';
import 'local_notification_payload.dart';
import 'local_notification_schedule.dart';
import 'local_notification_service.dart';
import 'notification_schedules.dart';

@pragma('vm:entry-point')
void localNotificationTapBackground(NotificationResponse response) {
  LocalNotificationPayload.decode(response.payload);
}

class AppLocalNotificationService implements LocalNotificationService {
  AppLocalNotificationService({
    required LoggerService logger,
    FlutterLocalNotificationsPlugin? plugin,
    String localTimeZoneName = 'America/Sao_Paulo',
  }) : _logger = logger,
       _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _localTimeZoneName = localTimeZoneName;

  static const _channelId = 'helpbari_reminders';
  static const _channelName = 'Lembretes';
  static const _channelDescription =
      'Lembretes de vitaminas, medicamentos e consultas.';

  final LoggerService _logger;
  final FlutterLocalNotificationsPlugin _plugin;
  final String _localTimeZoneName;

  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    timezone_data.initializeTimeZones();
    timezone.setLocalLocation(timezone.getLocation(_localTimeZoneName));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
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
    return cancel(notificationKey(payload.source, payload.entityId));
  }

  @override
  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }

  Future<void> _schedule(LocalNotificationSchedule schedule) async {
    await initialize();

    final granted = await requestPermissions();
    if (!granted) {
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
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  void _handleTap(NotificationResponse response) {
    final payload = LocalNotificationPayload.decode(response.payload);

    if (payload == null) {
      _logger.warning('Payload de notificacao invalido.');
      return;
    }

    _logger.info(
      'Notificacao aberta: ${payload.source.name}/${payload.entityId}',
    );
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
