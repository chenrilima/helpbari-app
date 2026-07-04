import 'dart:developer' as developer;

import '../config/environment.dart';

abstract final class AppLogger {
  static void debug(String message, {Object? error, StackTrace? stackTrace}) {
    if (!Environment.isDev) return;

    developer.log(
      message,
      name: 'HelpBari',
      error: error,
      stackTrace: stackTrace,
      level: 500,
    );
  }

  static void info(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'HelpBari',
      error: error,
      stackTrace: stackTrace,
      level: 800,
    );
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'HelpBari',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }
}
