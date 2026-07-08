import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

class FakeSettingsRepository implements SettingsRepository {
  AppSettings _settings = const AppSettings(id: 'local-settings');

  @override
  Future<AppSettings> getSettings() async {
    return _settings;
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
  }
}
