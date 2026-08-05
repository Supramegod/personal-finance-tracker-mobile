/// Dashboard presentation page setelah login.
///
/// Menampilkan:
/// 1. BalanceCard — saldo terkini + ringkasan income/expense (dari API)
/// 2. CalendarViewWidget — kalender bulanan dengan indikator transaksi
/// 3. InstallmentSummary — ringkasan cicilan aktif
/// 4. QuickActionRow — shortcut cepat (catat transaksi, riwayat)
/// 5. RecentTransactions — beberapa transaksi terakhir
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_components.dart';
import '../../../installments/presentation/providers/installment_provider.dart';
import '../../../installments/presentation/widgets/installment_card.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../transactions/presentation/widgets/transaction_tile.dart';
import '../../../reports/presentation/providers/report_provider.dart';
import '../../../reports/presentation/widgets/ai_insight_panel.dart';
import '../../domain/entities/balance.dart';
import '../providers/summary_provider.dart';
import '../widgets/balance_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(dashboardSummaryProvider);
    ref.invalidate(recentTransactionsProvider);
    ref.invalidate(installmentProvider);
    ref.invalidate(aiConsentProvider);
    ref.invalidate(latestAIInsightProvider);
    await Future.wait([
      ref.read(dashboardSummaryProvider.future),
      ref.read(recentTransactionsProvider.future),
    ]);
    ref.read(installmentProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final recentAsync = ref.watch(recentTransactionsProvider);
    final installmentState = ref.watch(installmentProvider);
    final summary = summaryAsync.valueOrNull ?? DashboardSummary.empty;

    final activeInstallments = installmentState.items
        .where((i) => !i.paid)
        .toList();
    final totalRemaining = activeInstallments.fold<double>(
      0,
      (sum, i) => sum + i.remainingAmount,
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat datang',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Text('Ringkasan keuangan'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Pengaturan',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Saldo Terkini
              BalanceCard(
                balance: summary.balance,
                totalIncome: summary.totalIncome,
                totalExpense: summary.totalExpense,
                isLoading: summaryAsync.isLoading,
                errorMessage: summaryAsync.hasError
                    ? 'Gagal memuat saldo'
                    : null,
                onRefresh: () => ref.invalidate(dashboardSummaryProvider),
              ),

              const SizedBox(height: AppSpacing.lg),

              const AIInsightPanel(compact: true),

              const SizedBox(height: AppSpacing.lg),

              SectionHeader(
                title: 'Cicilan berjalan',
                actionLabel: 'Kelola',
                onAction: () => context.push('/installments'),
              ),
              // Ringkasan Cicilan
              if (installmentState.items.isNotEmpty) ...[
                Card(
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
                            Text(
                              'Cicilan',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            TextButton(
                              onPressed: () => context.push('/installments'),
                              child: const Text('Lihat semua'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        if (activeInstallments.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.expenseLight,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.cardRadius,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: AppColors.expense,
                                  size: 18,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sisa Tanggungan',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.expense,
                                        ),
                                      ),
                                      Text(
                                        formatIdr(totalRemaining),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.expense,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${activeInstallments.length} aktif',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.expense,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ...activeInstallments
                              .take(3)
                              .map(
                                (i) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm,
                                  ),
                                  child: InstallmentCard(
                                    installment: i,
                                    onPay: () async {
                                      await ref
                                          .read(installmentProvider.notifier)
                                          .pay(i.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Berhasil bayar ${i.title}',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                        ] else
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Center(
                              child: Text(
                                'Semua cicilan lunas',
                                style: TextStyle(
                                  color: AppColors.textHint,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ] else
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.check_circle_outline,
                      color: AppColors.income,
                    ),
                    title: const Text('Tidak ada cicilan aktif'),
                    subtitle: const Text('Keuanganmu bebas dari tanggungan.'),
                  ),
                ),

              const SizedBox(height: AppSpacing.lg),

              SectionHeader(
                title: 'Transaksi terbaru',
                actionLabel: 'Lihat semua',
                onAction: () => context.go('/history'),
              ),
              Card(
                elevation: AppSpacing.cardElevation,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      recentAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, _) => Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Center(
                            child: Text(
                              e.toString(),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.error),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        data: (recent) {
                          if (recent.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Center(
                                child: Text(
                                  'Belum ada transaksi',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: AppColors.textHint),
                                ),
                              ),
                            );
                          }
                          return Column(
                            children: recent
                                .map(
                                  (tx) => TransactionTile(
                                    transaction: tx,
                                    onTap: () => context.push(
                                      '/add-transaction',
                                      extra: tx,
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.fabMargin + AppSpacing.fabSize),
            ],
          ),
        ),
      ),
    );
  }
}
