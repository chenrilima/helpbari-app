import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/local_settings_datasource.dart';
import '../dtos/settings_dto.dart';

class LocalSettingsRepository implements SettingsRepository {
  const LocalSettingsRepository(this._datasource);

  final LocalSettingsDatasource _datasource;

  @override
  Future<AppSettings> getSettings() async {
    final dto = await _datasource.getSettings();

    return dto?.toEntity() ??
        const AppSettings(id: LocalSettingsDatasource.defaultSettingsId);
  }

  @override
  Future<void> saveSettings(AppSettings settings) {
    return _datasource.save(
      SettingsDto.fromEntity(settings, now: DateTime.now()),
    );
  }
}
