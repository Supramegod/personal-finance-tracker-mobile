/// Layar Dashboard — halaman utama setelah login.
///
/// Menampilkan:
/// 1. BalanceCard — saldo terkini + ringkasan income/expense (dari API)
/// 2. SummaryChartCard — grafik income vs expense bulan berjalan
/// 3. QuickActionRow — shortcut cepat (catat transaksi, riwayat)
/// 4. RecentTransactionsCard — beberapa transaksi terakhir
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../models/balance.dart';
import '../../providers/auth_provider.dart';
import '../../providers/summary_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/summary_chart_card.dart';
import '../../widgets/transaction_tile.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(dashboardSummaryProvider);
    ref.invalidate(recentTransactionsProvider);
    await Future.wait([
      ref.read(dashboardSummaryProvider.future),
      ref.read(recentTransactionsProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final recentAsync = ref.watch(recentTransactionsProvider);
    final summary = summaryAsync.valueOrNull ?? DashboardSummary.empty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () => _confirmLogout(context, ref),
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
                errorMessage:
                    summaryAsync.hasError ? 'Gagal memuat saldo' : null,
                onRefresh: () => ref.invalidate(dashboardSummaryProvider),
              ),

              const SizedBox(height: AppSpacing.lg),

              // 2. Grafik Income vs Expense
              SummaryChartCard(
                incomeTotal: summary.totalIncome,
                expenseTotal: summary.totalExpense,
                periodLabel: 'Bulan Ini',
              ),

              const SizedBox(height: AppSpacing.lg),

              // 3. Quick Actions
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.add_circle_outline,
                      label: 'Catat Transaksi',
                      color: AppColors.primary,
                      onTap: () => context.push('/add-transaction'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.receipt_long_outlined,
                      label: 'Riwayat',
                      color: AppColors.secondary,
                      onTap: () => context.go('/history'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // 4. Transaksi Terakhir
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
                            'Transaksi Terakhir',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          TextButton(
                            onPressed: () => context.go('/history'),
                            child: const Text('Lihat Semua →'),
                          ),
                        ],
                      ),

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
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-transaction'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        tooltip: 'Tambah Transaksi',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Card(
        elevation: AppSpacing.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.md,
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
