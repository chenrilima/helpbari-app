enum AppEnvironment { dev, staging, prod }

abstract final class Environment {
  static AppEnvironment current = AppEnvironment.dev;

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const supabaseStorageBucket = String.fromEnvironment(
    'SUPABASE_STORAGE_BUCKET',
    defaultValue: 'helpbari',
  );
  static const appRedirectUrl = String.fromEnvironment(
    'APP_REDIRECT_URL',
    defaultValue: 'io.helpbari.app://login-callback',
  );

  static bool get isDev => current == AppEnvironment.dev;

  static bool get isStaging => current == AppEnvironment.staging;

  static bool get isProd => current == AppEnvironment.prod;

  static String get name => current.name;

  static bool get hasSupabaseConfig {
    return supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  }
}
