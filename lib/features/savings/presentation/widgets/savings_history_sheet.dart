/// Riwayat mutasi satu pot, dengan aksi membatalkan mutasi.
///
/// Membatalkan di sini adalah satu-satunya cara yang benar: transaksi yang
/// tercipta bersama mutasi ikut terhapus dalam satu transaksi DB. Menghapus
/// transaksinya dari halaman Transaksi ditolak backend.
library; // Savings history sheet.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../dashboard/presentation/providers/summary_provider.dart';
import '../../domain/entities/savings_entry.dart';
import '../providers/savings_provider.dart';

class SavingsHistorySheet extends ConsumerStatefulWidget {
  const SavingsHistorySheet({
    super.key,
    required this.goalId,
    required this.goalName,
  });

  final String goalId;
  final String goalName;

  @override
  ConsumerState<SavingsHistorySheet> createState() =>
      _SavingsHistorySheetState();
}

class _SavingsHistorySheetState extends ConsumerState<SavingsHistorySheet> {
  bool _isCanceling = false;
  bool _changed = false;

  Future<void> _cancel(SavingsEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Mutasi'),
        content: Text(
          'Batalkan ${entry.isDeposit ? 'setoran' : 'penarikan'} '
          '${formatIdr(entry.amount)}? Transaksi yang tercipta bersamanya '
          'ikut dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Batalkan Mutasi'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isCanceling = true);
    try {
      await ref
          .read(savingsProvider.notifier)
          .deleteEntry(id: widget.goalId, entryId: entry.id);
      if (!mounted) return;
      _changed = true;
      ref.invalidate(savingsDetailProvider(widget.goalId));
      // Membatalkan mutasi mengembalikan uang ke saldo kas.
      ref.invalidate(dashboardSummaryProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isCanceling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(savingsDetailProvider(widget.goalId));

    // canPop menahan penutupan selagi pembatalan berjalan; daftar tabungan
    // sudah dimuat ulang oleh notifier.deleteEntry, jadi tidak perlu load lagi
    // di sini (memanggil ref setelah pop berisiko menyentuh provider terlepas).
    return PopScope(
      canPop: !_isCanceling,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      namesRoute: true,
                      header: true,
                      child: Text(
                        'Riwayat — ${widget.goalName}',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context, _changed),
                    tooltip: 'Tutup',
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Flexible(
                child: detail.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  // Gagal-muat harus terlihat berbeda dari pot kosong.
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: AppSpacing.iconXLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text('$e', textAlign: TextAlign.center),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(
                            savingsDetailProvider(widget.goalId),
                          ),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                  data: (data) => data.entries.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: Text('Belum ada setoran maupun penarikan.'),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: data.entries.length,
                          itemBuilder: (context, index) {
                            final entry = data.entries[index];
                            return _EntryTile(
                              key: ValueKey(entry.id),
                              entry: entry,
                              isBusy: _isCanceling,
                              onCancel: () => _cancel(entry),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    super.key,
    required this.entry,
    required this.isBusy,
    required this.onCancel,
  });

  final SavingsEntry entry;
  final bool isBusy;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final color = entry.isDeposit ? AppColors.income : AppColors.expense;

    return ListTile(
      minTileHeight: 60,
      contentPadding: EdgeInsets.zero,
      // Ikon menemani warna supaya arah mutasi tidak hanya dibedakan warna.
      leading: Icon(
        entry.isDeposit ? Icons.south_west : Icons.north_east,
        color: color,
      ),
      title: Text(
        entry.note?.isNotEmpty == true
            ? entry.note!
            : (entry.isDeposit ? 'Setoran' : 'Penarikan'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(formatDate(entry.entryDate)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatIdrWithSign(entry.amount, isIncome: entry.isDeposit),
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          IconButton(
            onPressed: isBusy ? null : onCancel,
            tooltip:
                'Batalkan ${entry.isDeposit ? 'setoran' : 'penarikan'} '
                '${formatIdr(entry.amount)}',
            icon: const Icon(Icons.undo),
          ),
        ],
      ),
    );
  }
}
