import 'package:flutter/foundation.dart';

import '../config/environment.dart';

abstract interface class LoggerService {
  void info(String message);

  void warning(String message);

  void error(String message, {Object? error, StackTrace? stackTrace});
}

class AppLoggerService implements LoggerService {
  const AppLoggerService();

  @override
  void info(String message) {
    debugPrint('[INFO] $message');
  }

  @override
  void warning(String message) {
    debugPrint('[WARNING] $message');
  }

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    debugPrint('[ERROR] $message');

    if (Environment.isDev && error != null) {
      debugPrint('Error: ${error.runtimeType}');
    }

    if (Environment.isDev && stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }
  }
}
