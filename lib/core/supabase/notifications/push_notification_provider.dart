import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'push_notification_registration.dart';

final pushNotificationRegistrationProvider =
    Provider<PushNotificationRegistration>((ref) {
      return const SupabasePushNotificationRegistration();
    });
