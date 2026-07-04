import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/environment.dart';
import '../logger/app_logger.dart';

abstract final class SupabaseConfig {
  static Future<void> initialize() async {
    if (!Environment.hasSupabaseConfig) {
      AppLogger.debug(
        'Supabase config not found. Running app without Supabase connection.',
      );
      return;
    }

    await Supabase.initialize(
      url: Environment.supabaseUrl,
      publishableKey: Environment.supabaseAnonKey,
    );

    AppLogger.info('Supabase initialized successfully');
  }
}
