import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/services/clock_service.dart';
import 'package:helpbari/core/services/logger_service.dart';
import 'package:helpbari/core/services/notifications/notifications.dart';
import 'package:helpbari/features/appointments/application/appointment_reminder_service.dart';
import 'package:helpbari/features/appointments/domain/entities/entities.dart';
import 'package:helpbari/features/appointments/domain/value_objects/value_objects.dart';
import 'package:helpbari/features/settings/domain/entities/entities.dart';
import 'package:helpbari/features/settings/domain/repositories/repositories.dart';
import 'package:helpbari/features/settings/domain/usecases/use_cases.dart';

void main() {
  test(
    'reconciles schedule idempotently and cancels inactive appointments',
    () async {
      final notifications = _Notifications();
      final scheduler = NotificationScheduler(
        notifications: notifications,
        clock: const _Clock(),
        logger: const _Logger(),
      );
      await scheduler.restore(userId: 'user-a', schedules: const []);
      final service = AppointmentReminderService(
        settingsUseCases: SettingsUseCases(_Settings()),
        scheduler: scheduler,
        userId: 'user-a',
      );
      final appointment = Appointment(
        id: 'one',
        title: 'Retorno',
        date: AppointmentDate(DateTime(2030, 1, 1, 10)),
      );
      await service.applyAfterCommit(appointment);
      await service.applyAfterCommit(appointment);
      expect(notifications.updated, [
        'user-a:appointment:one',
        'user-a:appointment:one',
      ]);
      await service.applyAfterCommit(
        appointment.copyWith(status: AppointmentStatus.completed),
      );
      expect(notifications.canceled.last, 'user-a:appointment:one');
    },
  );
}

class _Settings implements SettingsRepository {
  @override
  Future<AppSettings> getSettings() async => const AppSettings(id: 'settings');
  @override
  Future<void> saveSettings(AppSettings settings) async {}
}

class _Notifications implements LocalNotificationService {
  final updated = <String>[];
  final canceled = <String>[];
  @override
  Future<void> update(LocalNotificationSchedule schedule) async =>
      updated.add(schedule.key);
  @override
  Future<void> cancelPayload(LocalNotificationPayload payload) async => canceled
      .add(notificationKey(payload.userId, payload.source, payload.entityId));
  @override
  Future<void> cancel(String key) async {}
  @override
  Future<void> cancelAll() async {}
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> requestPermissions() async => true;
  @override
  Future<NotificationPermissionState> permissionState() async =>
      NotificationPermissionState.granted;
  @override
  Future<String> localTimeZoneName() async => 'America/Sao_Paulo';
  @override
  Future<int> pendingCount() async => updated.length - canceled.length;
  @override
  Stream<LocalNotificationPayload> get taps => const Stream.empty();
  @override
  Future<void> reschedule(
    Iterable<LocalNotificationSchedule> schedules,
  ) async {}
  @override
  Future<void> scheduleOnce(LocalNotificationSchedule schedule) async {}
  @override
  Future<void> scheduleRecurring(LocalNotificationSchedule schedule) async {}
}

class _Clock implements ClockService {
  const _Clock();
  @override
  DateTime now() => DateTime(2026, 7, 12, 12);
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
