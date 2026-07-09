import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'SharedPreferences must be overridden at bootstrap.',
  );
});

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return SharedPreferencesLocalStorageService(
    ref.watch(sharedPreferencesProvider),
  );
});

final uuidServiceProvider = Provider<UuidService>((ref) {
  return const AppUuidService();
});

final clockServiceProvider = Provider<ClockService>((ref) {
  return const AppClockService();
});

final loggerServiceProvider = Provider<LoggerService>((ref) {
  return const AppLoggerService();
});

final localNotificationServiceProvider = Provider<LocalNotificationService>((
  ref,
) {
  return AppLocalNotificationService(logger: ref.read(loggerServiceProvider));
});
