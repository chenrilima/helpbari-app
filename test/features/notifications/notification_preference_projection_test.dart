import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/settings/application/notification_preference_projection_service.dart';
import 'package:helpbari/features/settings/domain/entities/entities.dart';
import 'package:helpbari/features/appointments/domain/entities/entities.dart';
import 'package:helpbari/features/appointments/domain/value_objects/value_objects.dart';
import 'package:timezone/data/latest.dart' as tz_data;

void main() {
  setUpAll(tz_data.initializeTimeZones);

  test(
    'creates only explicitly configured category times in their IANA zone',
    () {
      final service = const NotificationPreferenceProjectionService(
        windowDays: 2,
      );
      final now = DateTime.utc(2026, 7, 21, 10);
      final result = service.project(
        userId: 'user-a',
        preferences: const NotificationPreferences(
          globalEnabled: true,
          categories: {
            NotificationCategory.water: true,
            NotificationCategory.meals: true,
          },
          times: [
            NotificationTimePreference(
              id: 'water-morning',
              category: NotificationCategory.water,
              kind: NotificationScheduleKind.daily,
              hour: 8,
              minute: 0,
              timeZone: 'America/Sao_Paulo',
            ),
          ],
        ),
        nowUtc: now,
        appointments: const [],
      );

      expect(result, hasLength(3));
      expect(
        result.every((item) => item.category == NotificationCategory.water),
        isTrue,
      );
      expect(result.first.scheduleAtUtc.hour, 11);
    },
  );

  test(
    'global, category and time disablement produce no concrete projection',
    () {
      const time = NotificationTimePreference(
        id: 'meal-time',
        category: NotificationCategory.meals,
        kind: NotificationScheduleKind.daily,
        hour: 12,
        minute: 0,
        timeZone: 'UTC',
        enabled: false,
      );
      final result = const NotificationPreferenceProjectionService().project(
        userId: 'user-a',
        preferences: const NotificationPreferences(
          globalEnabled: true,
          categories: {NotificationCategory.meals: true},
          times: [time],
        ),
        nowUtc: DateTime.utc(2026, 7, 21),
        appointments: const [],
      );
      expect(result, isEmpty);
    },
  );

  test('appointment lead, edit and cancellation update projections', () {
    const preferences = NotificationPreferences(
      globalEnabled: true,
      categories: {NotificationCategory.appointments: true},
      times: [
        NotificationTimePreference(
          id: 'appointments-lead',
          category: NotificationCategory.appointments,
          kind: NotificationScheduleKind.appointmentLead,
          hour: 0,
          minute: 0,
          timeZone: 'UTC',
          leadMinutes: 30,
        ),
      ],
    );
    final service = const NotificationPreferenceProjectionService();
    final now = DateTime.utc(2026, 7, 21, 10);
    final appointment = Appointment(
      id: 'appointment-a',
      title: 'Sensitive title never enters payload',
      date: AppointmentDate(DateTime.utc(2026, 7, 22, 14)),
    );

    final first = service.project(
      userId: 'user-a',
      preferences: preferences,
      nowUtc: now,
      appointments: [appointment],
    );
    final edited = service.project(
      userId: 'user-a',
      preferences: preferences,
      nowUtc: now,
      appointments: [
        appointment.copyWith(
          date: AppointmentDate(DateTime.utc(2026, 7, 22, 16)),
        ),
      ],
    );
    final canceled = service.project(
      userId: 'user-a',
      preferences: preferences,
      nowUtc: now,
      appointments: [appointment.copyWith(status: AppointmentStatus.canceled)],
    );

    expect(first.single.scheduleAtUtc, DateTime.utc(2026, 7, 22, 13, 30));
    expect(edited.single.scheduleAtUtc, DateTime.utc(2026, 7, 22, 15, 30));
    expect(canceled, isEmpty);
  });
}
