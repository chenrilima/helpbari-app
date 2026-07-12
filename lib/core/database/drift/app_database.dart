import 'package:drift/drift.dart';

import 'daos/water_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/profile_dao.dart';
import 'daos/weight_dao.dart';
import 'daos/meal_dao.dart';
import 'daos/appointment_dao.dart';
import 'database_connection.dart';
import 'tables/local_migrations.dart';
import 'tables/sync_cursors.dart';
import 'tables/sync_devices.dart';
import 'tables/water_records.dart';
import 'tables/water_cutovers.dart';
import 'tables/settings_records.dart';
import 'tables/settings_cutovers.dart';
import 'tables/profile_records.dart';
import 'tables/profile_cutovers.dart';
import 'tables/weight_records.dart';
import 'tables/weight_cutovers.dart';
import 'tables/meal_records.dart';
import 'tables/meal_cutovers.dart';
import 'tables/appointment_records.dart';
import 'tables/appointment_cutovers.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    WaterRecords,
    SyncCursors,
    SyncDevices,
    LocalMigrations,
    WaterCutovers,
    SettingsRecords,
    SettingsCutovers,
    ProfileRecords,
    ProfileCutovers,
    WeightRecords,
    WeightCutovers,
    MealRecords,
    MealCutovers,
    AppointmentRecords,
    AppointmentCutovers,
  ],
  daos: [WaterDao, SettingsDao, ProfileDao, WeightDao, MealDao, AppointmentDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? openHelpBariDatabase());

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) await migrator.createTable(waterCutovers);
      if (from < 3) {
        await migrator.createTable(settingsRecords);
        await migrator.createTable(settingsCutovers);
      }
      if (from < 4) {
        await migrator.createTable(profileRecords);
        await migrator.createTable(profileCutovers);
      }
      if (from < 5) {
        await migrator.addColumn(
          profileRecords,
          profileRecords.photoStoragePath,
        );
      }
      if (from < 6) {
        await migrator.createTable(weightRecords);
        await migrator.createTable(weightCutovers);
      }
      if (from < 7) {
        await migrator.createTable(mealRecords);
        await migrator.createTable(mealCutovers);
      }
      if (from < 8) {
        await migrator.createTable(appointmentRecords);
        await migrator.createTable(appointmentCutovers);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
