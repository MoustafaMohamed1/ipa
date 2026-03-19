/// Environment configuration.
///
/// Values are injected at build time via `--dart-define`:
///
/// ```bash
/// # Development (Android emulator → host)
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
///
/// # Development (physical device on same Wi-Fi)
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.X:3000
///
/// # Staging
/// flutter build apk --release --dart-define=API_BASE_URL=https://staging-api.tenovia.sa
///
/// # Production
/// flutter build apk --release --dart-define=API_BASE_URL=https://api.tenovia.sa
/// ```
class Env {
  Env._();

  static const String _configuredApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Tenovia',
  );

  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );

  static String get apiBaseUrl {
    if (_configuredApiBaseUrl.isNotEmpty) {
      return _configuredApiBaseUrl;
    }

    if (isProduction) {
      throw StateError(
        'API_BASE_URL is required when PRODUCTION=true. Pass it via --dart-define=API_BASE_URL=...',
      );
    }

    return 'http://10.0.2.2:3000';
  }
}
