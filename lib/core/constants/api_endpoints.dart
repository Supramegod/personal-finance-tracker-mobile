/// Definisi endpoint API backend.
///
/// Semua URL endpoint dikumpulkan di sini agar mudah diubah
/// saat development (local/staging/production).
///
/// `baseUrl` bisa dioverride saat build tanpa ubah kode:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
/// - Android emulator lokal: http://10.0.2.2:8080
/// - Device fisik (LAN):      http://<ip-laptop>:8080
/// - Produksi (default):      https://jalu-finance.shelterdev.online
library;

abstract final class ApiEndpoints {
  // ── Base URL ─────────────────────────────────────────────────────
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://jalu-finance.shelterdev.online',
  );
  static const String apiPrefix = '/api/v1';

  /// Base + prefix, dipakai sebagai BaseOptions.baseUrl pada Dio.
  /// Path di repository ditulis relatif (mis. '/transactions').
  static const String apiRoot = '$baseUrl$apiPrefix';

  // ── Auth ─────────────────────────────────────────────────────────
  static const String login = '/auth/login'; // POST
  static const String refresh = '/auth/refresh'; // POST
  static const String logout = '/auth/logout'; // POST
  static const String switchGroup = '/auth/switch-group'; // POST

  // ── Groups ───────────────────────────────────────────────────────
  static const String groups = '/groups'; // GET / POST

  // ── Transactions ─────────────────────────────────────────────────
  static const String transactions = '/transactions'; // GET / POST
  static String transaction(String id) => '/transactions/$id'; // GET / PUT / DELETE
  static const String calendar = '/transactions/calendar'; // GET (?year=&month=)

  // ── Categories ───────────────────────────────────────────────────
  static const String categories = '/categories'; // GET

  // ── Summary ──────────────────────────────────────────────────────
  static const String balance = '/summary/balance'; // GET
  static const String report = '/summary/report'; // GET (?period=&from=&to=)
}
