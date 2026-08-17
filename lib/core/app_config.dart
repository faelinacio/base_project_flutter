/// Application-wide configuration, resolved at build/run time via `--dart-define`.
///
/// Example:
/// ```
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
/// ```
///
/// Defaults to `http://localhost:8080` (the base_project_spring_boot default), which
/// works for web and desktop targets. Android emulators must use `10.0.2.2` instead of
/// `localhost` to reach the host machine.
class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
}
