/// Konstanta spacing yang konsisten di seluruh aplikasi.
///
/// Semua jarak (margin, padding, gap) HARUS menggunakan nilai dari sini.
/// Berbasis kelipatan 4px sesuai standar Material Design.
library;

abstract final class AppSpacing {
  // ── Base Units ───────────────────────────────────────────────────
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  // ── Screen Padding ───────────────────────────────────────────────
  static const double screenHorizontal = lg;
  static const double screenVertical = lg;

  // ── Card ─────────────────────────────────────────────────────────
  static const double cardPadding = lg;
  static const double cardRadius = 16.0;
  static const double cardElevation = 0.0;

  // ── List Tile ────────────────────────────────────────────────────
  static const double tileHorizontalPadding = lg;
  static const double tileVerticalPadding = sm;

  // ── Button ───────────────────────────────────────────────────────
  static const double buttonHeight = 48.0;
  static const double buttonRadius = 12.0;

  // ── Input ────────────────────────────────────────────────────────
  static const double inputRadius = 8.0;

  // ── Avatar / Icon ────────────────────────────────────────────────
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;

  // ── Chip ─────────────────────────────────────────────────────────
  static const double chipHeight = 32.0;
  static const double chipRadius = 16.0;

  // ── FAB ──────────────────────────────────────────────────────────
  static const double fabMargin = lg;
  static const double fabSize = 56.0;
}
