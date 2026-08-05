/// Widget kartu cicilan milik feature installments.
///
/// Progress bar menunjukkan perbandingan paidCount / tenorMonths.
/// Tombol "Bayar" hanya muncul untuk cicilan yang belum lunas.
/// Setelah lunas, hanya tombol hapus yang tersedia.
library;

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/installment.dart';

class InstallmentCard extends StatelessWidget {
  final Installment installment;
  final VoidCallback? onPay;
  final VoidCallback? onDelete;

  const InstallmentCard({
    super.key,
    required this.installment,
    this.onPay,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final progress = installment.progress;
    final isCompleted = installment.paid;

    return Card(
      elevation: AppSpacing.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        installment.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        installment.categoryName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.incomeLight
                        : AppColors.expenseLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isCompleted ? 'Lunas' : 'Aktif',
                    style: TextStyle(
                      color: isCompleted ? AppColors.income : AppColors.expense,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.divider,
                color: isCompleted ? AppColors.income : AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${installment.paidCount}/${installment.tenorMonths} bulan',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  formatIdr(installment.totalAmount),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: AppColors.textHint),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${formatIdr(installment.monthlyAmount)} / bulan',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: AppColors.textHint),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  isCompleted
                      ? 'Selesai: ${formatDate(installment.completionDate!)}'
                      : 'Jatuh tempo: ${formatDate(installment.nextDueDate)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (!isCompleted) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Hapus'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.expense,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onPay,
                      icon: const Icon(Icons.payment, size: 18),
                      label: const Text('Bayar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Hapus'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.expense,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
