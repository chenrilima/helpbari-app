import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/bootstrap/app_bootstrap.dart';
import 'core/config/environment.dart';

Future<void> main() async {
  await bootstrap(
    environment: AppEnvironment.dev,
    builder: () async {
      runApp(const ProviderScope(child: HelpBariApp()));
    },
  );
}