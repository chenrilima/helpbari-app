import 'package:drift/drift.dart';

import 'daos/water_dao.dart';
import 'database_connection.dart';
import 'tables/local_migrations.dart';
import 'tables/sync_cursors.dart';
import 'tables/sync_devices.dart';
import 'tables/water_records.dart';
import 'tables/water_cutovers.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    WaterRecords,
    SyncCursors,
    SyncDevices,
    LocalMigrations,
    WaterCutovers,
  ],
  daos: [WaterDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? openHelpBariDatabase());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) await migrator.createTable(waterCutovers);
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
