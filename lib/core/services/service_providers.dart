import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services.dart';

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
