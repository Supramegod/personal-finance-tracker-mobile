/// Halaman Tabungan: daftar pot, ringkasan total, dan filter status.
library; // Savings page.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../dashboard/presentation/providers/summary_provider.dart';
import '../../domain/entities/savings_goal.dart';
import '../providers/savings_provider.dart';
import '../widgets/savings_card.dart';
import '../widgets/savings_entry_sheet.dart';
import '../widgets/savings_form.dart';
import '../widgets/savings_history_sheet.dart';

const _statusFilters = <({String value, String label})>[
  (value: '', label: 'Semua'),
  (value: 'active', label: 'Aktif'),
  (value: 'completed', label: 'Tercapai'),
  (value: 'archived', label: 'Diarsipkan'),
];

class SavingsPage extends ConsumerWidget {
  const SavingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(savingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tabungan')),
      body: state.isLoading && state.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null && state.items.isEmpty
          ? _ErrorView(message: state.errorMessage!)
          : RefreshIndicator(
              onRefresh: () => ref.read(savingsProvider.notifier).load(),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                children: [
                  _SummaryCard(totalSaved: state.totalSaved,
                      goalCount: state.items.length),
                  const SizedBox(height: AppSpacing.md),
                  _StatusFilterBar(selected: state.statusFilter),
                  const SizedBox(height: AppSpacing.md),
                  if (state.items.isEmpty)
                    _EmptyView(hasFilter: state.statusFilter.isNotEmpty)
                  else
                    ...state.items.map(
                      (goal) => Padding(
                        key: ValueKey(goal.id),
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: SavingsCard(
                          goal: goal,
                          onDeposit: () => _openEntry(context, ref, goal,
                              isWithdraw: false),
                          onWithdraw: () => _openEntry(context, ref, goal,
                              isWithdraw: true),
                          onHistory: () => _openHistory(context, goal),
                          onEdit: () => _openForm(context, goal: goal),
                          onDelete: () => _confirmDelete(context, ref, goal),
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
        onPressed: () => _openForm(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Tabungan'),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {SavingsGoal? goal}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SavingsForm(goal: goal),
    );
  }

  Future<void> _openEntry(
    BuildContext context,
    WidgetRef ref,
    SavingsGoal goal, {
    required bool isWithdraw,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SavingsEntrySheet(goal: goal, isWithdraw: isWithdraw),
    );
    if (saved != true || !context.mounted) return;

    // Saldo kas ikut bergerak, jadi ringkasan dashboard harus dimuat ulang.
    ref.invalidate(dashboardSummaryProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isWithdraw ? 'Penarikan tercatat' : 'Setoran tercatat'),
      ),
    );
  }

  Future<void> _openHistory(BuildContext context, SavingsGoal goal) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          SavingsHistorySheet(goalId: goal.id, goalName: goal.name),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SavingsGoal goal,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Tabungan'),
        content: Text(
          'Hapus "${goal.name}"? Saldonya harus kosong dulu — tarik seluruh '
          'isinya sebelum menghapus.',
        ),
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
    if (ok != true || !context.mounted) return;

    try {
      await ref.read(savingsProvider.notifier).delete(goal.id);
    } catch (e) {
      if (!context.mounted) return;
      // Backend menolak (409) bila pot masih bersaldo; pesannya sudah ramah.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.totalSaved, required this.goalCount});

  final double totalSaved;
  final int goalCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: AppColors.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Row(
          children: [
            const Icon(Icons.savings_outlined, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total tabungan', style: theme.textTheme.bodySmall),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatIdr(totalSaved),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text('$goalCount pot', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _StatusFilterBar extends ConsumerWidget {
  const _StatusFilterBar({required this.selected});

  final String selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _statusFilters.map((filter) {
          final isSelected = filter.value == selected;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ChoiceChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (_) => ref
                  .read(savingsProvider.notifier)
                  .setStatusFilter(filter.value),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.hasFilter});

  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const Icon(
            Icons.savings_outlined,
            size: AppSpacing.iconXLarge,
            color: AppColors.textHint,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            hasFilter
                ? 'Tidak ada tabungan dengan status ini'
                : 'Belum ada tabungan. Mulai sisihkan uang untuk tujuan tertentu.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends ConsumerWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
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
              message,
              style: const TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () => ref.read(savingsProvider.notifier).load(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
