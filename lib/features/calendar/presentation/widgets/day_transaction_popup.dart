/// Popup detail transaksi harian milik feature calendar.
///
/// Menampilkan:
/// - Header: tanggal yang diformat
/// - List transaksi dengan warna type (hijau untuk income, merah untuk expense)
/// - Ringkasan footer: total income + total expense
/// - Loading / error / empty state
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/calendar_provider.dart';

class DayTransactionPopup extends ConsumerWidget {
  final DateTime date;

  const DayTransactionPopup({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(dayTransactionsProvider(date));

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatDate(date),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(),
            // Content
            SizedBox(
              width: double.maxFinite,
              child: txAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error),
                        const SizedBox(height: 4),
                        const Text(
                          'Gagal memuat',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(dayTransactionsProvider(date)),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Center(
                        child: Text(
                          'Tidak ada transaksi',
                          style: TextStyle(color: AppColors.textHint),
                        ),
                      ),
                    );
                  }

                  double totalIncome = 0;
                  double totalExpense = 0;

                  for (final item in items) {
                    if (item.isIncome) {
                      totalIncome += item.amount;
                    } else {
                      totalExpense += item.amount;
                    }
                  }

                  final txWidgets = items.map<Widget>((item) {
                    final isIncome = item.isIncome;
                    final amount = item.amount;
                    final category = item.categoryName;
                    final note = item.note;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isIncome
                                  ? AppColors.income
                                  : AppColors.expense,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                                if (note != null && note.isNotEmpty)
                                  Text(
                                    note,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppColors.textHint),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '${isIncome ? "+" : "-"}${formatIdr(amount)}',
                            style: TextStyle(
                              color: isIncome
                                  ? AppColors.income
                                  : AppColors.expense,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();

                  return Column(
                    children: [
                      ...txWidgets,
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Pemasukan',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            formatIdr(totalIncome),
                            style: const TextStyle(
                              color: AppColors.income,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Pengeluaran',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            formatIdr(totalExpense),
                            style: const TextStyle(
                              color: AppColors.expense,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
