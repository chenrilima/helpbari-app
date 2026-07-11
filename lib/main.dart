import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/bootstrap/app_bootstrap.dart';
import 'core/services/service_providers.dart';
import 'core/config/environment.dart';
import 'core/database/drift/app_database.dart';
import 'core/database/drift/drift_database_providers.dart';
import 'core/database/drift/migrations/water_local_migration_service.dart';
import 'core/services/local_storage_service.dart';

Future<void> main() async {
  await bootstrap(
    environment: Environment.configuredEnvironment,
    builder: () async {
      final preferences = await SharedPreferences.getInstance();
      final database = AppDatabase();
      await database.customSelect('SELECT 1').getSingle();
      await WaterLocalMigrationService(
        database: database,
        storage: SharedPreferencesLocalStorageService(preferences),
      ).migrate();

      runApp(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            appDatabaseProvider.overrideWith((ref) {
              ref.onDispose(database.close);
              return Future.value(database);
            }),
          ],
          child: const HelpBariApp(),
        ),
      );
    },
  );
}
