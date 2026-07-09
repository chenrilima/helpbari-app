import '../../../../core/database/database.dart';
import '../../../../core/services/clock_service.dart';
import '../dtos/settings_dto.dart';

class LocalSettingsDatasource {
  const LocalSettingsDatasource({
    required LocalDatabase database,
    required ClockService clock,
  }) : _database = database,
       _clock = clock;

  static const collection = 'settings';
  static const defaultSettingsId = 'local-settings';

  final LocalDatabase _database;
  final ClockService _clock;

  Future<SettingsDto?> getSettings() async {
    final record = await _database.getById(collection, defaultSettingsId);
    if (record == null || record.isDeleted) return null;

    return SettingsDto.fromRecord(record);
  }

  Future<void> save(SettingsDto settings) async {
    final previous = await _database.getById(collection, settings.id);
    final dto = SettingsDto.fromEntity(
      settings.toEntity(),
      now: _clock.now(),
      previousMetadata: previous?.metadata,
    );

    await _database.upsert(collection, dto.toRecord());
  }
}
