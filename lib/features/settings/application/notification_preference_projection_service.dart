import 'package:timezone/timezone.dart' as tz;

import '../../../core/services/notifications/notifications.dart';
import '../../appointments/domain/entities/entities.dart';
import '../../smart_routines/application/routine_notification_projection.dart';
import '../domain/entities/entities.dart';

final class NotificationPreferenceProjectionService {
  const NotificationPreferenceProjectionService({this.windowDays = 14});

  final int windowDays;

  List<RoutineNotificationProjection> project({
    required String userId,
    required NotificationPreferences preferences,
    required DateTime nowUtc,
    required Iterable<Appointment> appointments,
  }) {
    if (!preferences.globalEnabled) return const [];
    return [
      ..._appointments(userId, preferences, nowUtc, appointments),
      ...preferences.times.expand(
        (time) => _configuredTime(userId, preferences, nowUtc, time),
      ),
    ];
  }

  Iterable<RoutineNotificationProjection> _appointments(
    String userId,
    NotificationPreferences preferences,
    DateTime nowUtc,
    Iterable<Appointment> appointments,
  ) sync* {
    if (!preferences.categoryEnabled(NotificationCategory.appointments)) {
      return;
    }
    final lead = preferences.times
        .where(
          (item) =>
              item.category == NotificationCategory.appointments &&
              item.kind == NotificationScheduleKind.appointmentLead &&
              item.enabled,
        )
        .firstOrNull;
    final leadMinutes = lead?.leadMinutes ?? 0;
    for (final appointment in appointments) {
      if (!appointment.isScheduled ||
          !preferences.itemEnabled(
            NotificationCategory.appointments,
            appointment.id,
          )) {
        continue;
      }
      final scheduledAt = appointment.date.value.toUtc().subtract(
        Duration(minutes: leadMinutes),
      );
      if (!scheduledAt.isAfter(nowUtc)) continue;
      yield RoutineNotificationProjection(
        occurrenceId: appointment.id,
        scheduleAtUtc: scheduledAt,
        userId: userId,
        actions: const {},
        category: NotificationCategory.appointments,
        itemId: appointment.id,
        timeId: lead?.id ?? 'legacy-at-time',
        source: NotificationSource.appointment,
      );
    }
  }

  Iterable<RoutineNotificationProjection> _configuredTime(
    String userId,
    NotificationPreferences preferences,
    DateTime nowUtc,
    NotificationTimePreference time,
  ) sync* {
    if (time.category == NotificationCategory.treatment ||
        time.category == NotificationCategory.appointments ||
        !preferences.timeEnabled(time)) {
      return;
    }
    tz.Location location;
    try {
      location = time.timeZone == 'UTC'
          ? tz.UTC
          : tz.getLocation(time.timeZone);
    } on tz.LocationNotFoundException {
      return;
    }
    final localNow = tz.TZDateTime.from(nowUtc, location);
    for (var offset = 0; offset <= windowDays; offset++) {
      final day = tz.TZDateTime(
        location,
        localNow.year,
        localNow.month,
        localNow.day + offset,
        time.hour,
        time.minute,
      );
      if (time.kind == NotificationScheduleKind.weekly &&
          day.weekday != time.isoWeekday) {
        continue;
      }
      final instant = day.toUtc();
      if (!instant.isAfter(nowUtc)) continue;
      final entityId =
          '${time.category.name}:${time.id}:'
          '${day.year.toString().padLeft(4, '0')}-'
          '${day.month.toString().padLeft(2, '0')}-'
          '${day.day.toString().padLeft(2, '0')}';
      yield RoutineNotificationProjection(
        occurrenceId: entityId,
        scheduleAtUtc: instant,
        userId: userId,
        actions: const {},
        category: time.category,
        itemId: time.itemId ?? time.category.name,
        timeId: time.id,
        source: _source(time.category),
      );
    }
  }

  NotificationSource _source(NotificationCategory category) =>
      switch (category) {
        NotificationCategory.water => NotificationSource.water,
        NotificationCategory.meals => NotificationSource.meal,
        NotificationCategory.weight => NotificationSource.weight,
        NotificationCategory.appointments => NotificationSource.appointment,
        NotificationCategory.treatment =>
          NotificationSource.smartRoutineOccurrence,
      };
}
