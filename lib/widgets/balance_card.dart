/// Widget kartu saldo untuk Dashboard.
///
/// Menampilkan saldo terkini di tengah, dengan ringkasan
/// total income (hijau) dan expense (merah) di bagian bawah.
///
/// Menggunakan [AppSpacing] dan [AppColors] — tanpa hard-code value.
library;

import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_spacing.dart';
import '../core/constants/app_text_styles.dart';
import '../core/utils/formatters.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final double totalIncome;
  final double totalExpense;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRefresh;

  const BalanceCard({
    super.key,
    this.balance = 0,
    this.totalIncome = 0,
    this.totalExpense = 0,
    this.isLoading = false,
    this.errorMessage,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppSpacing.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: AppSpacing.iconMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(errorMessage!, style: AppTextStyles.errorMessage(context)),
              if (onRefresh != null) ...[
                const SizedBox(height: AppSpacing.sm),
                TextButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label Saldo
        Text('Saldo Terkini', style: AppTextStyles.balanceTitle(context)),

        const SizedBox(height: AppSpacing.xs),

        // Nominal Saldo (besar)
        Text(
          formatIdr(balance),
          style: AppTextStyles.balanceAmount(context),
        ),

        const SizedBox(height: AppSpacing.md),

        // Ringkasan Income vs Expense
        Row(
          children: [
            // Income Chip
            _SummaryChip(
              label: 'Pemasukan',
              amount: totalIncome,
              color: AppColors.income,
              backgroundColor: AppColors.incomeLight,
            ),
            const SizedBox(width: AppSpacing.sm),
            // Expense Chip
            _SummaryChip(
              label: 'Pengeluaran',
              amount: totalExpense,
              color: AppColors.expense,
              backgroundColor: AppColors.expenseLight,
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final Color backgroundColor;

  const _SummaryChip({
    required this.label,
    required this.amount,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$label ${formatIdr(amount)}',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
