/// Installment presentation page untuk cicilan aktif dan lunas.
///
/// Fitur:
/// - Ringkasan total sisa tanggungan untuk cicilan aktif.
/// - Pull-to-refresh untuk memuat ulang data.
/// - FAB untuk menambah cicilan baru via bottom sheet.
/// - Konfirmasi dialog sebelum bayar dan hapus.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/installment.dart';
import '../providers/installment_provider.dart';
import '../widgets/installment_card.dart';
import '../widgets/installment_form.dart';

class InstallmentPage extends ConsumerWidget {
  const InstallmentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(installmentProvider);
    final items = state.items;
    final activeItems = items.where((i) => !i.paid).toList();
    final completedItems = items.where((i) => i.paid).toList();
    final totalRemaining = activeItems.fold<double>(
      0,
      (sum, i) => sum + i.remainingAmount,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Cicilan')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: AppSpacing.iconXLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    state.errorMessage!,
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: () =>
                        ref.read(installmentProvider.notifier).load(),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(installmentProvider.notifier).load(),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                children: [
                  if (activeItems.isNotEmpty)
                    Card(
                      color: AppColors.expenseLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.cardRadius,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.cardPadding),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.expense,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sisa Tanggungan',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppColors.expense),
                                  ),
                                  Text(
                                    formatIdr(totalRemaining),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: AppColors.expense,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${activeItems.length} aktif',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.expense),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  if (activeItems.isNotEmpty) ...[
                    Text(
                      'Aktif',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...activeItems.map(
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: InstallmentCard(
                          installment: i,
                          onPay: () => _confirmPay(context, ref, i),
                          onDelete: () => _confirmDelete(context, ref, i),
                        ),
                      ),
                    ),
                  ],
                  if (completedItems.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Lunas',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...completedItems.map(
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: InstallmentCard(
                          installment: i,
                          onDelete: () => _confirmDelete(context, ref, i),
                        ),
                      ),
                    ),
                  ],
                  if (items.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          children: [
                            Icon(
                              Icons.credit_card_off,
                              size: AppSpacing.iconXLarge,
                              color: AppColors.textHint,
                            ),
                            SizedBox(height: AppSpacing.sm),
                            Text(
                              'Belum ada cicilan',
                              style: TextStyle(color: AppColors.textHint),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(
                    height: AppSpacing.fabMargin + AppSpacing.fabSize,
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => const InstallmentForm(),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Cicilan'),
      ),
    );
  }

  Future<void> _confirmPay(
    BuildContext context,
    WidgetRef ref,
    Installment i,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bayar Cicilan'),
        content: Text(
          'Bayar ${formatIdr(i.monthlyAmount)} untuk "${i.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Bayar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(installmentProvider.notifier).pay(i.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Berhasil bayar ${i.title}')));
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Installment i,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Cicilan'),
        content: Text('Yakin ingin menghapus "${i.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(installmentProvider.notifier).delete(i.id);
    }
  }
}
