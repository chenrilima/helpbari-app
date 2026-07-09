import '../../../features/appointments/domain/entities/entities.dart';
import '../../../features/medications/domain/entities/entities.dart';
import '../../../features/vitamins/domain/entities/entities.dart';
import 'app_local_notification_service.dart';
import 'local_notification_payload.dart';
import 'local_notification_schedule.dart';

abstract final class NotificationSchedules {
  static LocalNotificationSchedule vitamin(Vitamin vitamin) {
    final payload = LocalNotificationPayload(
      source: NotificationSource.vitamin,
      entityId: vitamin.id,
    );

    return LocalNotificationSchedule(
      key: notificationKey(payload.source, payload.entityId),
      title: 'Hora da vitamina',
      body: 'Registre ${vitamin.formattedName}.',
      scheduledAt: _todayAt(
        hour: vitamin.scheduleTime.hour,
        minute: vitamin.scheduleTime.minute,
      ),
      recurrence: LocalNotificationRecurrence.daily,
      payload: payload,
    );
  }

  static LocalNotificationSchedule medication(Medication medication) {
    final payload = LocalNotificationPayload(
      source: NotificationSource.medication,
      entityId: medication.id,
    );

    return LocalNotificationSchedule(
      key: notificationKey(payload.source, payload.entityId),
      title: 'Hora do medicamento',
      body: 'Registre ${medication.formattedName}.',
      scheduledAt: _todayAt(
        hour: medication.scheduleTime.hour,
        minute: medication.scheduleTime.minute,
      ),
      recurrence: LocalNotificationRecurrence.daily,
      payload: payload,
    );
  }

  static LocalNotificationSchedule appointment(Appointment appointment) {
    final payload = LocalNotificationPayload(
      source: NotificationSource.appointment,
      entityId: appointment.id,
    );

    return LocalNotificationSchedule(
      key: notificationKey(payload.source, payload.entityId),
      title: 'Consulta agendada',
      body: appointment.location == null
          ? appointment.title
          : '${appointment.title} em ${appointment.location}',
      scheduledAt: appointment.date.value,
      payload: payload,
    );
  }

  static DateTime _todayAt({required int hour, required int minute}) {
    final now = DateTime.now();

    return DateTime(now.year, now.month, now.day, hour, minute);
  }
}
