import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/app/router/notification_navigation.dart';
import 'package:helpbari/core/services/notifications/notifications.dart';

void main() {
  for (final entry in <NotificationSource, String>{
    NotificationSource.appointment: '/appointments',
    NotificationSource.vitamin: '/treatment',
    NotificationSource.medication: '/treatment',
    NotificationSource.smartRoutineOccurrence: '/treatment',
  }.entries) {
    test('routes ${entry.key.name} payload to its entity list', () {
      final location = notificationLocation(
        LocalNotificationPayload(
          source: entry.key,
          entityId: 'entity-1',
          userId: 'user-a',
        ),
      );
      expect(location, '${entry.value}?entityId=entity-1');
    });
  }

  test('does not route unsupported push payload', () {
    expect(
      notificationLocation(
        const LocalNotificationPayload(
          source: NotificationSource.push,
          entityId: 'one',
          userId: 'user-a',
        ),
      ),
      isNull,
    );
  });

  test(
    'routes configurable tracking categories to their canonical screens',
    () {
      const sources = {
        NotificationSource.water: '/water',
        NotificationSource.meal: '/meals',
        NotificationSource.weight: '/weight',
      };
      for (final entry in sources.entries) {
        final location = notificationLocation(
          LocalNotificationPayload(
            source: entry.key,
            entityId: 'configured-reminder',
            userId: 'user-a',
          ),
        );
        expect(Uri.parse(location!).path, entry.value);
      }
    },
  );
}
