/// Widget baris transaksi — digunakan di Dashboard (3 item) dan Riwayat (list).
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
import '../core/constants/app_colors.dart';
import '../core/constants/app_spacing.dart';
import '../core/utils/formatters.dart';
import '../models/transaction.dart';

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
      leading: _CategoryIcon(
        icon: _mapIcon(transaction.categoryIcon,
            isIncome: transaction.type.isIncome),
        color: transaction.type.isIncome ? AppColors.income : AppColors.expense,
      ),
      title: Text(
        transaction.categoryName,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
      subtitle: transaction.note != null && transaction.note!.isNotEmpty
          ? Text(
              transaction.note!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Text(
        formatIdrWithSign(transaction.amount, isIncome: transaction.type.isIncome),
        style: TextStyle(
          color: transaction.type.isIncome ? AppColors.income : AppColors.expense,
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
                  style: TextButton.styleFrom(foregroundColor: AppColors.expense),
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

  /// Map icon string dari API ke IconData Flutter.
  static IconData _mapIcon(String? iconName, {bool isIncome = false}) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'work':
        return Icons.work;
      case 'directions_car':
        return Icons.directions_car;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'health_and_safety':
        return Icons.health_and_safety;
      case 'school':
        return Icons.school;
      case 'home':
        return Icons.home;
      case 'flight':
        return Icons.flight;
      default:
        return isIncome ? Icons.arrow_upward : Icons.arrow_downward;
    }
  }
}

class _CategoryIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _CategoryIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
