import 'package:timezone/data/latest.dart' as timezone_data;

/// Initializes the bundled IANA database without selecting a process-wide
/// local zone. Domain services continue to receive an explicit IANA zone.
abstract final class IanaTimezoneBootstrap {
  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static void initialize() {
    if (_initialized) return;
    timezone_data.initializeTimeZones();
    _initialized = true;
  }
}
