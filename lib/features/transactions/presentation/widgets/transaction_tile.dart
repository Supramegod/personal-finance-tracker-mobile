/// Widget baris transaksi milik feature transactions.
///
/// Menampilkan:
/// - Leading: icon kategori (lingkaran)
/// - Title: nama kategori
/// - Subtitle: catatan (jika ada)
/// - Trailing: jumlah (+ hijau / - merah)
///
/// Mendukung swipe-to-delete dan onTap untuk edit.
library;

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/transaction.dart';
import 'category_visual.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.tileHorizontalPadding,
        vertical: AppSpacing.tileVerticalPadding,
      ),
      leading: CategoryIconBadge(
        iconName: transaction.categoryIcon,
        type: transaction.type,
      ),
      title: Text(
        transaction.categoryName,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: transaction.note != null && transaction.note!.isNotEmpty
          ? Text(
              transaction.note!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: .62),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Text(
        formatIdrWithSign(
          transaction.amount,
          isIncome: transaction.type.isIncome,
        ),
        style: TextStyle(
          color: transaction.type.isIncome
              ? AppColors.income
              : AppColors.expense,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );

    // Bungkus dengan Dismissible jika onDelete disediakan
    if (onDelete != null) {
      return Dismissible(
        key: ValueKey(transaction.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          color: AppColors.expense,
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        confirmDismiss: (_) async {
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Hapus Transaksi'),
              content: Text(
                'Yakin ingin menghapus "${transaction.categoryName}" '
                'sebesar ${formatIdr(transaction.amount)}?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.expense,
                  ),
                  child: const Text('Hapus'),
                ),
              ],
            ),
          );
        },
        onDismissed: (_) => onDelete!(),
        child: tile,
      );
    }

    return tile;
  }
}
