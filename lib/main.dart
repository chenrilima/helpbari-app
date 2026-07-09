import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/bootstrap/app_bootstrap.dart';
import 'core/services/service_providers.dart';
import 'core/config/environment.dart';

Future<void> main() async {
  await bootstrap(
    environment: AppEnvironment.dev,
    builder: () async {
      final preferences = await SharedPreferences.getInstance();

      runApp(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
          child: const HelpBariApp(),
        ),
      );
    },
  );
}
