import 'package:shared_preferences/shared_preferences.dart';

abstract interface class LocalStorageService {
  bool? getBool(String key);

  Future<void> setBool(String key, bool value);

  String? getString(String key);

  Future<void> setString(String key, String value);
}

final class SharedPreferencesLocalStorageService
    implements LocalStorageService {
  const SharedPreferencesLocalStorageService(this._preferences);

  final SharedPreferences _preferences;

  @override
  bool? getBool(String key) => _preferences.getBool(key);

  @override
  Future<void> setBool(String key, bool value) async {
    await _preferences.setBool(key, value);
  }

  @override
  String? getString(String key) => _preferences.getString(key);

  @override
  Future<void> setString(String key, String value) async {
    await _preferences.setString(key, value);
  }
}
