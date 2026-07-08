import '../entities/entities.dart';

abstract interface class SettingsRepository {
  Future<AppSettings> getSettings();

  Future<void> saveSettings(AppSettings settings);
}
