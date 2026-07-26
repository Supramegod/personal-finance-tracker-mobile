/// Gaya teks aplikasi Personal Finance Tracker.
///
/// Menggunakan `Theme.of(context).textTheme` sebagai basis.
/// Hanya mendefinisikan kustomisasi khusus app di sini.
library;

import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  // ── Balance Display ──────────────────────────────────────────────
  static TextStyle balanceTitle(BuildContext context) {
    return Theme.of(context).textTheme.titleSmall!.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        );
  }

  static TextStyle balanceAmount(BuildContext context) {
    return Theme.of(context).textTheme.headlineLarge!.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        );
  }

  // ── Income / Expense Label ──────────────────────────────────────────
  static TextStyle incomeLabel(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
          color: AppColors.income,
          fontWeight: FontWeight.w600,
        );
  }

  static TextStyle expenseLabel(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
          color: AppColors.expense,
          fontWeight: FontWeight.w600,
        );
  }

  // ── Transaction Amount ───────────────────────────────────────────
  static TextStyle transactionAmountIncome(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge!.copyWith(
          color: AppColors.income,
          fontWeight: FontWeight.w600,
        );
  }

  static TextStyle transactionAmountExpense(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge!.copyWith(
          color: AppColors.expense,
          fontWeight: FontWeight.w600,
        );
  }

  // ── Section Header ───────────────────────────────────────────────
  static TextStyle sectionHeader(BuildContext context) {
    return Theme.of(context).textTheme.titleSmall!.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        );
  }

  // ── Error Message ────────────────────────────────────────────────
  static TextStyle errorMessage(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
          color: AppColors.error,
        );
  }

  // ── Empty State ──────────────────────────────────────────────────
  static TextStyle emptyTitle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
          color: AppColors.textSecondary,
        );
  }

  static TextStyle emptySubtitle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: AppColors.textHint,
        );
  }
}
