import '../../../../core/services/logger_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/database/drift/migrations/settings_legacy_service.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/drift_settings_local_datasource.dart';
import '../datasources/local_settings_datasource.dart';
import '../dtos/settings_dto.dart';

class DriftSettingsRepository implements SettingsRepository {
  const DriftSettingsRepository({
    required this.datasource,
    required this.fallback,
    required this.legacy,
    required this.userId,
    required this.logger,
    required this.storage,
  });
  final Future<DriftSettingsLocalDatasource> Function() datasource;
  final LocalSettingsDatasource fallback;
  final Future<SettingsLegacyService> Function() legacy;
  final String userId;
  final LoggerService logger;
  final LocalStorageService storage;

  Future<DriftSettingsLocalDatasource> _resolve() async {
    final value = await datasource();
    await (await legacy()).ensureUserAndAttemptCutover(userId);
    return value;
  }

  @override
  Future<AppSettings> getSettings() async {
    try {
      return (await (await _resolve()).getSettings()).toEntity();
    } catch (error) {
      if (SettingsLegacyService.hasCutoverMirrorFor(storage, userId)) {
        throw StateError('Configurações indisponíveis temporariamente.');
      }
      logger.warning(
        'Settings Drift unavailable; legacy read fallback (${error.runtimeType}).',
      );
      return (await fallback.getSettings())?.toEntity() ??
          AppSettings(id: userId);
    }
  }

  @override
  Future<void> saveSettings(AppSettings settings) async =>
      (await _resolve()).save(
        SettingsDto.fromEntity(settings, now: DateTime.now(), userId: userId),
      );
}
