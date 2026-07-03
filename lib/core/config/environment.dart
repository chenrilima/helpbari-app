enum AppEnvironment {
  dev,
  prod,
}

abstract final class Environment {
  static AppEnvironment current = AppEnvironment.dev;

  static bool get isDev => current == AppEnvironment.dev;

  static bool get isProd => current == AppEnvironment.prod;

  static String get name => current.name;
}