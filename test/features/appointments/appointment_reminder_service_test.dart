import 'package:flutter_test/flutter_test.dart';
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
      final service = AppointmentReminderService(
        settingsUseCases: SettingsUseCases(_Settings()),
        notifications: notifications,
      );
      final appointment = Appointment(
        id: 'one',
        title: 'Retorno',
        date: AppointmentDate(DateTime.now().add(const Duration(days: 1))),
      );
      await service.applyAfterCommit(appointment);
      await service.applyAfterCommit(appointment);
      expect(notifications.updated, ['appointment:one', 'appointment:one']);
      await service.applyAfterCommit(
        appointment.copyWith(status: AppointmentStatus.completed),
      );
      expect(notifications.canceled.last, 'appointment:one');
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
  Future<void> cancelPayload(LocalNotificationPayload payload) async =>
      canceled.add(notificationKey(payload.source, payload.entityId));
  @override
  Future<void> cancel(String key) async {}
  @override
  Future<void> cancelAll() async {}
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> requestPermissions() async => true;
  @override
  Future<void> reschedule(
    Iterable<LocalNotificationSchedule> schedules,
  ) async {}
  @override
  Future<void> scheduleOnce(LocalNotificationSchedule schedule) async {}
  @override
  Future<void> scheduleRecurring(LocalNotificationSchedule schedule) async {}
}
