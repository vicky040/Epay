/// Build-time configuration.
///
/// Point the app at your backend with:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
///
/// 10.0.2.2 is the Android emulator's alias for the host machine's localhost.
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );

  /// When the backend is unreachable the app transparently serves bundled
  /// demo data so every screen stays explorable. Set to false to surface
  /// network errors instead.
  static const bool demoFallback = bool.fromEnvironment(
    'DEMO_FALLBACK',
    defaultValue: true,
  );

  static const String appName = 'EPay';
  static const String tagline = 'Smart Investment & Earning Platform';
  static const String supportHours = '08:00 — 20:00 IST';
  static const String telegramUrl = 'https://t.me/epay_official';
}
