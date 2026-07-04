import 'package:flutter/widgets.dart';

import '../../core/config/environment.dart';
import '../../core/logger/app_logger.dart';
import '../../core/supabase/supabase_config.dart';

Future<void> bootstrap({
  required AppEnvironment environment,
  required Future<void> Function() builder,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  Environment.current = environment;

  AppLogger.info('Starting HelpBari in ${Environment.name} mode');

  await SupabaseConfig.initialize();

  await builder();
}
