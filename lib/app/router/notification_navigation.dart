import '../../core/services/notifications/notifications.dart';
import 'app_routes.dart';

String? notificationLocation(LocalNotificationPayload payload) {
  final route = switch (payload.source) {
    NotificationSource.appointment => AppRoutes.appointments,
    NotificationSource.water => AppRoutes.water,
    NotificationSource.meal => AppRoutes.meals,
    NotificationSource.weight => AppRoutes.weight,
    NotificationSource.vitamin => AppRoutes.vitamins,
    NotificationSource.medication => AppRoutes.medications,
    NotificationSource.smartRoutineOccurrence => AppRoutes.home,
    NotificationSource.push => null,
  };
  if (route == null) return null;
  return Uri(
    path: route,
    queryParameters: {'entityId': payload.entityId},
  ).toString();
}
