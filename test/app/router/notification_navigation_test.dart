import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/app/router/notification_navigation.dart';
import 'package:helpbari/core/services/notifications/notifications.dart';

void main() {
  for (final entry in <NotificationSource, String>{
    NotificationSource.appointment: '/appointments',
    NotificationSource.vitamin: '/vitamins',
    NotificationSource.medication: '/medications',
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
}
