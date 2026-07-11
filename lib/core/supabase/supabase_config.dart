import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/environment.dart';
import '../logger/app_logger.dart';

abstract final class SupabaseConfig {
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static Future<void> initialize() async {
    if (!Environment.hasSupabaseConfig) {
      AppLogger.debug(
        'Supabase config not found. Running app without Supabase connection.',
      );
      return;
    }

    if (_isInitialized) return;

    await Supabase.initialize(
      url: Environment.supabaseUrl,
      publishableKey: Environment.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

    _isInitialized = true;
    AppLogger.info(
      'Supabase initialized successfully: ${Environment.supabaseUrl}',
    );
  }
}
