import 'package:flutter/widgets.dart';

import '../../core/config/environment.dart';
import '../../core/logger/app_logger.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/time/iana_timezone_bootstrap.dart';

Future<void> bootstrap({
  required AppEnvironment environment,
  required Future<void> Function() builder,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  Environment.current = environment;
  IanaTimezoneBootstrap.initialize();

  AppLogger.info('Starting HelpBari in ${Environment.name} mode');

  if (!Environment.isDev && !Environment.hasSupabaseConfig) {
    throw StateError(
      'Supabase configuration is required in ${Environment.name}.',
    );
  }

  await SupabaseConfig.initialize();

  await builder();
}
