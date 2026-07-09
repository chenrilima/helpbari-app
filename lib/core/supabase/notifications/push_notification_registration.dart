abstract interface class PushNotificationRegistration {
  Future<void> registerDeviceToken(String token);

  Future<void> unregisterDeviceToken(String token);
}

class SupabasePushNotificationRegistration
    implements PushNotificationRegistration {
  const SupabasePushNotificationRegistration();

  @override
  Future<void> registerDeviceToken(String token) {
    throw UnimplementedError(
      'Push notification registration will be implemented with the provider integration.',
    );
  }

  @override
  Future<void> unregisterDeviceToken(String token) {
    throw UnimplementedError(
      'Push notification unregister will be implemented with the provider integration.',
    );
  }
}
