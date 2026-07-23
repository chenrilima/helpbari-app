import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/bootstrap/app_bootstrap.dart';
import 'core/config/environment.dart';
import 'core/database/drift/bootstrap/drift_bootstrap_service.dart';
import 'core/database/drift/drift_database_providers.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/logger_service.dart';
import 'core/services/service_providers.dart';
import 'core/sync/sync_providers.dart';

Future<void> main() async {
  await bootstrap(
    environment: Environment.configuredEnvironment,
    builder: () async {
      final preferences = await SharedPreferences.getInstance();
      final packageInfo = await PackageInfo.fromPlatform();
      final driftResult = await DriftBootstrapService(
        storage: SharedPreferencesLocalStorageService(preferences),
        logger: const AppLoggerService(),
      ).initialize();
      final database = driftResult.database;

      runApp(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            syncAppVersionProvider.overrideWithValue(
              '${packageInfo.version}+${packageInfo.buildNumber}',
            ),
            driftAvailableProvider.overrideWithValue(database != null),
            if (database != null)
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
