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
    'https://jalu-finance.shelterdev.online',
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
  static String groupMembers(String id) => '/groups/$id/members'; // GET / POST
  static String groupMember(String groupId, String userId) =>
      '/groups/$groupId/members/$userId'; // DELETE
  static String groupAIConsent(String id) => '/groups/$id/ai-consent';

  // ── Users ────────────────────────────────────────────────────────
  static const String users = '/users'; // GET / POST

  // ── Transactions ─────────────────────────────────────────────────
  static const String transactions = '/transactions'; // GET / POST
  static String transaction(String id) =>
      '/transactions/$id'; // GET / PUT / DELETE
  static const String calendar =
      '/transactions/calendar'; // GET (?year=&month=)

  // ── Installments ─────────────────────────────────────────────────
  static const String installments = '/installments'; // GET / POST
  static String installment(String id) => '/installments/$id'; // DELETE
  static String installmentPay(String id) => '/installments/$id/pay'; // POST

  // ── Savings / Tabungan ───────────────────────────────────────────
  static const String savings = '/savings'; // GET / POST
  static String savingsDetail(String id) => '/savings/$id'; // GET/PUT/DELETE
  static String savingsDeposit(String id) => '/savings/$id/deposit'; // POST
  static String savingsWithdraw(String id) => '/savings/$id/withdraw'; // POST
  static String savingsEntry(String id, String entryId) =>
      '/savings/$id/entries/$entryId'; // DELETE

  // ── Categories ───────────────────────────────────────────────────
  static const String categories = '/categories'; // GET

  // ── Summary ──────────────────────────────────────────────────────
  static const String balance = '/summary/balance'; // GET
  static const String report = '/summary/report'; // GET (?period=&from=&to=)
  static const String aiInsights = '/summary/ai-insights';
  static const String latestAIInsight = '/summary/ai-insights/latest';
  static const String regenerateAIInsight =
      '/summary/ai-insights/regenerate'; // POST (?month=YYYY-MM), owner-only
}
