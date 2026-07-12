import '../../../services/local_storage_service.dart';
import '../../../services/logger_service.dart';
import '../app_database.dart';
import '../consistency/water_local_consistency_checker.dart';
import '../consistency/water_local_consistency_report.dart';
import '../migrations/water_local_migration_report.dart';
import '../migrations/water_local_migration_service.dart';
import '../migrations/settings_legacy_service.dart';
import '../migrations/profile_legacy_service.dart';
import '../migrations/weight_legacy_service.dart';
import '../migrations/meal_legacy_service.dart';

typedef AppDatabaseFactory = Future<AppDatabase> Function();

class DriftBootstrapService {
  DriftBootstrapService({
    required LocalStorageService storage,
    required LoggerService logger,
    AppDatabaseFactory? databaseFactory,
  }) : _storage = storage,
       _logger = logger,
       _databaseFactory = databaseFactory ?? _defaultDatabaseFactory;

  final LocalStorageService _storage;
  final LoggerService _logger;
  final AppDatabaseFactory _databaseFactory;

  Future<DriftBootstrapResult> initialize() async {
    AppDatabase? database;
    try {
      database = await _databaseFactory();
      await database.customSelect('SELECT 1').getSingle();
      final migration = await WaterLocalMigrationService(
        database: database,
        storage: _storage,
      ).migrate();
      await SettingsLegacyService(
        database: database,
        storage: _storage,
      ).migrate();
      await ProfileLegacyService(
        database: database,
        storage: _storage,
      ).migrate();
      await WeightLegacyService(
        database: database,
        storage: _storage,
      ).migrate();
      await MealLegacyService(database: database, storage: _storage).migrate();
      final consistency = await WaterLocalConsistencyChecker(
        database: database,
        storage: _storage,
      ).check();

      _logger.info(
        'Drift bootstrap completed: '
        'legacy=${consistency.legacyRecords}, '
        'drift=${consistency.driftRecords}, '
        'consistent=${consistency.consistent}',
      );
      return DriftBootstrapResult.success(
        database: database,
        migration: migration,
        consistency: consistency,
      );
    } catch (error) {
      if (database != null) {
        try {
          await database.close();
        } catch (_) {
          // The primary SharedPreferences flow must remain available.
        }
      }
      _logger.warning(
        'Drift bootstrap unavailable; using primary local storage '
        '(${error.runtimeType}).',
      );
      return const DriftBootstrapResult.failure();
    }
  }

  static Future<AppDatabase> _defaultDatabaseFactory() async => AppDatabase();
}

class DriftBootstrapResult {
  const DriftBootstrapResult._({
    required this.database,
    required this.migration,
    required this.consistency,
  });

  const DriftBootstrapResult.failure()
    : this._(database: null, migration: null, consistency: null);

  factory DriftBootstrapResult.success({
    required AppDatabase database,
    required WaterLocalMigrationReport migration,
    required WaterLocalConsistencyReport consistency,
  }) {
    return DriftBootstrapResult._(
      database: database,
      migration: migration,
      consistency: consistency,
    );
  }

  final AppDatabase? database;
  final WaterLocalMigrationReport? migration;
  final WaterLocalConsistencyReport? consistency;

  bool get isAvailable => database != null;
}
