/// Palet warna aplikasi Personal Finance Tracker.
///
/// Semua warna HARUS didefinisikan di sini, jangan hard-code hex di widget.
/// Gunakan: `AppColors.primary` bukan `Color(0xFF...)`.
///
/// Berbasis Material Design 3 dengan primary Teal.
library;

import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Primary Palette ──────────────────────────────────────────────
  static const Color primary = Color(0xFF63C7A6);
  static const Color primaryLight = Color(0xFF91D9C1);
  static const Color primaryDark = Color(0xFF319779);
  static const Color onPrimary = Color(0xFF0B2A21);

  // ── Accent / Secondary ───────────────────────────────────────────
  static const Color secondary = Color(0xFFF4B860); // Amber
  static const Color onSecondary = Color(0xFF000000);

  // ── Semantic Colors ──────────────────────────────────────────────
  static const Color income = Color(0xFF4ADE80);
  static const Color incomeLight = Color(0xFF163A2A);
  static const Color expense = Color(0xFFFF6B6B);
  static const Color expenseLight = Color(0xFF422126);

  // ── Neutral / Surface ────────────────────────────────────────────
  static const Color background = Color(0xFFF5F7F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF181A1B);
  static const Color surfaceDark = Color(0xFF202325);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBackgroundDark = Color(0xFF282C2F);

  // ── Text ─────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFE8EBE9);
  static const Color textSecondaryDark = Color(0xFFA7ACA9);

  // ── Divider & Border ─────────────────────────────────────────────
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFBDBDBD);
  static const Color borderFocused = primary;

  // ── Status ───────────────────────────────────────────────────────
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1976D2);

  // ── Chart ────────────────────────────────────────────────────────
  static const Color chartIncome = Color(0xFF66BB6A);
  static const Color chartExpense = Color(0xFFEF5350);
  static const Color chartGrid = Color(0xFFEEEEEE);
}
