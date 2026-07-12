import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database.dart';
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

final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  return SharedPreferencesLocalDatabase(ref.watch(localStorageServiceProvider));
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

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  final scheduler = NotificationScheduler(
    notifications: ref.watch(localNotificationServiceProvider),
    clock: ref.watch(clockServiceProvider),
    logger: ref.watch(loggerServiceProvider),
  );
  ref.onDispose(scheduler.dispose);
  return scheduler;
});

final notificationSchedulerStateProvider =
    StreamProvider<NotificationSchedulerState>((ref) async* {
      final scheduler = ref.watch(notificationSchedulerProvider);
      yield scheduler.state;
      yield* scheduler.states;
    });
