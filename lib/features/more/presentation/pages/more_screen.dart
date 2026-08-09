import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../calendar/presentation/providers/calendar_provider.dart';
import '../../../dashboard/presentation/providers/summary_provider.dart';
import '../../../groups/domain/entities/group.dart';
import '../../../groups/presentation/providers/group_provider.dart';
import '../../../installments/presentation/providers/installment_provider.dart';
import '../../../transactions/presentation/providers/category_provider.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../reports/presentation/providers/report_provider.dart';

class MoreScreen extends ConsumerStatefulWidget {
  // More shell feature page.
  const MoreScreen({super.key});

  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen> {
  bool _switching = false;

  Future<void> _chooseGroup() async {
    final state = ref.read(groupProvider);
    if (state.groups.isEmpty || _switching) return;

    final selected = await showModalBottomSheet<Group>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pilih kelompok aktif',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Saldo dan transaksi akan mengikuti kelompok yang dipilih.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              ...state.groups.map(
                (group) => ListTile(
                  minTileHeight: 60,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: .13),
                    child: const Icon(
                      Icons.groups_2_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    group.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(group.isOwner ? 'Owner' : 'Anggota'),
                  trailing: state.activeGroupId == group.id
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(context, group),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected == null || selected.id == state.activeGroupId || !mounted) {
      return;
    }
    setState(() => _switching = true);
    try {
      await ref.read(groupProvider.notifier).switchGroup(selected.id);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(recentTransactionsProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(calendarProvider);
      ref.invalidate(aiConsentProvider);
      ref.invalidate(aiInsightProvider);
      ref.invalidate(latestAIInsightProvider);
      await Future.wait([
        ref.read(transactionListProvider.notifier).load(),
        ref.read(installmentProvider.notifier).load(),
      ]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Berpindah ke ${selected.name}')),
        );
        context.go('/dashboard');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal berpindah kelompok: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupProvider);
    final activeGroup = groups.activeGroup;
    return Scaffold(
      appBar: AppBar(title: const Text('Lainnya')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: [
          Text(
            'Kelola keuanganmu',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Fitur tambahan dan preferensi akun.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: .65),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Kelompok aktif',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            color: AppColors.primary.withValues(alpha: .08),
            child: ListTile(
              minTileHeight: 76,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.groups_2_outlined,
                  color: AppColors.primary,
                ),
              ),
              title: Text(
                activeGroup?.name ??
                    (groups.isLoading ? 'Memuat...' : 'Belum ada kelompok'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                activeGroup == null
                    ? 'Buat kelompok melalui Kelola Anggota'
                    : '${activeGroup.isOwner ? 'Owner' : 'Anggota'} • Ketuk untuk berpindah',
              ),
              trailing: _switching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.unfold_more_rounded),
              onTap: groups.groups.isEmpty ? null : _chooseGroup,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _MoreItem(
            icon: Icons.credit_card_outlined,
            color: AppColors.secondary,
            title: 'Cicilan',
            subtitle: 'Pantau tanggungan dan pembayaran',
            onTap: () => context.push('/installments'),
          ),
          _MoreItem(
            icon: Icons.savings_outlined,
            color: AppColors.primary,
            title: 'Tabungan',
            subtitle: 'Sisihkan uang untuk tujuan tertentu',
            onTap: () => context.push('/savings'),
          ),
          _MoreItem(
            icon: Icons.calendar_month_outlined,
            color: AppColors.info,
            title: 'Kalender',
            subtitle: 'Lihat aktivitas berdasarkan tanggal',
            onTap: () => context.push('/calendar'),
          ),
          _MoreItem(
            icon: Icons.people_outline,
            color: AppColors.income,
            title: 'Kelola Anggota',
            subtitle: 'Atur grup dan pengguna bersama',
            onTap: () => context.push('/members'),
          ),
          const SizedBox(height: AppSpacing.lg),
          _MoreItem(
            icon: Icons.settings_outlined,
            color: AppColors.primary,
            title: 'Pengaturan',
            subtitle: 'Tema, akun, dan keamanan',
            onTap: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }
}

class _MoreItem extends StatelessWidget {
  const _MoreItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Card(
      child: ListTile(
        minTileHeight: 72,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    ),
  );
}
