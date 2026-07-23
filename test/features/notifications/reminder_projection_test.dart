import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/services/services.dart';
import 'package:helpbari/features/medications/application/medication_reminder_service.dart';
import 'package:helpbari/features/medications/domain/entities/entities.dart';
import 'package:helpbari/features/medications/domain/value_objects/value_objects.dart';
import 'package:helpbari/features/settings/domain/entities/entities.dart';
import 'package:helpbari/features/settings/domain/repositories/repositories.dart';
import 'package:helpbari/features/settings/domain/usecases/use_cases.dart';
import 'package:helpbari/features/vitamins/application/vitamin_reminder_service.dart';
import 'package:helpbari/features/vitamins/domain/entities/entities.dart';
import 'package:helpbari/features/vitamins/domain/value_objects/value_objects.dart';

void main() {
  test(
    'legacy medication and vitamin services never create parallel schedules',
    () async {
      final notifications = _Notifications();
      final scheduler = _scheduler(notifications);
      await scheduler.restore(userId: 'user-a', schedules: const []);
      final settings = SettingsUseCases(
        _Settings(const AppSettings(id: 'user-a')),
      );
      final medicationService = MedicationReminderService(
        settingsUseCases: settings,
        scheduler: scheduler,
        clock: const _Clock(),
        userId: 'user-a',
      );
      final vitaminService = VitaminReminderService(
        settingsUseCases: settings,
        scheduler: scheduler,
        clock: const _Clock(),
        userId: 'user-a',
      );
      final medication = Medication(
        id: 'med-1',
        name: MedicationName.create('Omeprazol')!,
        scheduleTime: const MedicationScheduleTime(hour: 8, minute: 30),
      );
      final vitamin = Vitamin(
        id: 'vit-1',
        name: VitaminName.create('Vitamina B12')!,
        scheduleTime: const VitaminScheduleTime(hour: 9, minute: 0),
      );

      await medicationService.scheduleIfEnabled(medication);
      await vitaminService.scheduleIfEnabled(vitamin);

      expect(notifications.pending, isEmpty);

      await medicationService.cancel(medication.id);
      await vitaminService.cancel(vitamin.id);
      expect(notifications.pending, isEmpty);
    },
  );

  test('disabled settings prevent concrete local schedules', () async {
    final notifications = _Notifications();
    final scheduler = _scheduler(notifications);
    await scheduler.restore(userId: 'user-a', schedules: const []);
    final settings = SettingsUseCases(
      _Settings(
        const AppSettings(
          id: 'user-a',
          medicationRemindersEnabled: false,
          vitaminRemindersEnabled: false,
        ),
      ),
    );

    await MedicationReminderService(
      settingsUseCases: settings,
      scheduler: scheduler,
      clock: const _Clock(),
      userId: 'user-a',
    ).scheduleIfEnabled(
      Medication(
        id: 'med-1',
        name: MedicationName.create('Omeprazol')!,
        scheduleTime: const MedicationScheduleTime(hour: 8, minute: 30),
      ),
    );
    await VitaminReminderService(
      settingsUseCases: settings,
      scheduler: scheduler,
      clock: const _Clock(),
      userId: 'user-a',
    ).scheduleIfEnabled(
      Vitamin(
        id: 'vit-1',
        name: VitaminName.create('Vitamina B12')!,
        scheduleTime: const VitaminScheduleTime(hour: 9, minute: 0),
      ),
    );

    expect(notifications.pending, isEmpty);
  });
}

NotificationScheduler _scheduler(_Notifications notifications) =>
    NotificationScheduler(
      notifications: notifications,
      clock: const _Clock(),
      logger: const _Logger(),
    );

class _Settings implements SettingsRepository {
  const _Settings(this.settings);
  final AppSettings settings;

  @override
  Future<AppSettings> getSettings() async => settings;

  @override
  Future<void> saveSettings(AppSettings settings) async {}
}

class _Notifications implements LocalNotificationService {
  final Map<String, LocalNotificationSchedule> pending = {};

  @override
  Future<void> update(LocalNotificationSchedule schedule) async =>
      pending[schedule.key] = schedule;
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
  Future<bool> requestPermissions() async => true;
  @override
  Future<NotificationPermissionState> permissionState() async =>
      NotificationPermissionState.granted;
  @override
  Future<String> localTimeZoneName() async => 'America/Sao_Paulo';
  @override
  Future<int> pendingCount() async => pending.length;
  @override
  Stream<LocalNotificationPayload> get taps => const Stream.empty();
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
}

class _Clock implements ClockService {
  const _Clock();
  @override
  DateTime now() => DateTime(2026, 7, 20, 12);
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
