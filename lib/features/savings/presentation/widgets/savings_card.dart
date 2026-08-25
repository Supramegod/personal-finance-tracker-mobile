/// Kartu satu pot tabungan: saldo terkumpul, progres target, saran setoran
/// bulanan, dan aksi setor/tarik.
library; // Savings goal card widget.

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/savings_goal.dart';

class SavingsCard extends StatelessWidget {
  const SavingsCard({
    super.key,
    required this.goal,
    required this.onDeposit,
    required this.onWithdraw,
    required this.onHistory,
    required this.onEdit,
    required this.onDelete,
  });

  final SavingsGoal goal;
  final VoidCallback onDeposit;
  final VoidCallback onWithdraw;
  final VoidCallback onHistory;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = goal.hasTarget
        ? 'Target ${formatIdr(goal.targetAmount!)}'
        : 'Tanpa target';

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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                _StatusChip(status: goal.status),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Terkumpul', style: theme.textTheme.bodySmall),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatIdr(goal.savedAmount),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.income,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (goal.hasTarget)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Kurang', style: theme.textTheme.bodySmall),
                      Text(
                        formatIdr(goal.remainingAmount ?? 0),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (goal.hasTarget) ...[
              const SizedBox(height: AppSpacing.md),
              _SavingsProgress(goal: goal),
            ],
            if (goal.hasTarget &&
                goal.suggestedMonthly != null &&
                !goal.isCompleted) ...[
              const SizedBox(height: AppSpacing.md),
              _SuggestionBox(goal: goal),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onDeposit,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Setor'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    // onPressed null (bukan callback kosong) supaya semantics
                    // tombolnya benar-benar berstatus disabled.
                    onPressed: goal.canWithdraw ? onWithdraw : null,
                    child: const Text('Tarik'),
                  ),
                ),
                IconButton(
                  onPressed: onHistory,
                  tooltip: 'Riwayat mutasi ${goal.name}',
                  icon: const Icon(Icons.history),
                ),
                IconButton(
                  onPressed: onEdit,
                  tooltip: 'Ubah tabungan ${goal.name}',
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  onPressed: onDelete,
                  tooltip: 'Hapus tabungan ${goal.name}',
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.expense,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SavingsProgress extends StatelessWidget {
  const _SavingsProgress({required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthsLeft = goal.monthsLeft;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Persentase juga hadir sebagai teks: panjang bar saja tidak cukup
            // sebagai penanda, dan warna tidak boleh jadi satu-satunya makna.
            Text('${goal.percent}% tercapai', style: theme.textTheme.bodySmall),
            if (monthsLeft != null)
              Text(
                monthsLeft > 0 ? '$monthsLeft bulan lagi' : 'Jatuh tempo',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        // LinearProgressIndicator tidak mengumumkan nilainya sendiri ke
        // pembaca layar — tanpa Semantics ini, bar-nya sama sekali tak terbaca.
        Semantics(
          container: true,
          label: 'Progres tabungan ${goal.name}',
          value:
              '${goal.percent} persen, '
              '${formatIdr(goal.savedAmount)} dari ${formatIdr(goal.targetAmount!)}',
          child: ExcludeSemantics(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: goal.percent / 100,
                minHeight: 6,
                backgroundColor: AppColors.divider,
                color: goal.isCompleted ? AppColors.income : AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SuggestionBox extends StatelessWidget {
  const _SuggestionBox({required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final behind = goal.isOnTrack == false;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: (behind ? AppColors.expense : AppColors.primary).withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sisihkan ${formatIdr(goal.suggestedMonthly!)}/bulan '
            'untuk mengejar target',
            style: theme.textTheme.bodySmall,
          ),
          if (goal.isOnTrack != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Row(
              children: [
                // Ikon menemani warna: status tidak boleh disampaikan warna saja.
                Icon(
                  behind ? Icons.warning_amber_rounded : Icons.check_circle,
                  size: 14,
                  color: behind ? AppColors.expense : AppColors.income,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  behind ? 'Tertinggal dari jadwal' : 'Sesuai jadwal',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: behind ? AppColors.expense : AppColors.income,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'completed' => ('Tercapai', AppColors.income),
      'archived' => ('Diarsipkan', AppColors.textHint),
      _ => ('Aktif', AppColors.primary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
