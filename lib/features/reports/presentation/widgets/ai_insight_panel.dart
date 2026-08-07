import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/financial_insight.dart';
import '../providers/report_provider.dart';

class AIInsightPanel extends ConsumerWidget {
  const AIInsightPanel({
    super.key,
    this.month,
    this.onMonthChanged,
    this.compact = false,
  });
  final DateTime? month;
  final ValueChanged<DateTime>? onMonthChanged;
  final bool compact;

  String get monthKey => month == null
      ? ''
      : '${month!.year}-${month!.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consent = ref.watch(aiConsentProvider);
    return consent.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, _) => _MessageCard(
        icon: Icons.cloud_off_rounded,
        title: 'Insight AI belum tersedia',
        message: 'Tarik untuk mencoba memuat kembali.',
      ),
      data: (value) {
        if (!value.enabled) return _ConsentCard(consent: value);
        final insightAsync = compact
            ? ref.watch(latestAIInsightProvider)
            : ref.watch(aiInsightProvider(monthKey));
        final content = insightAsync.when(
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (_, _) => const _MessageCard(
            icon: Icons.auto_awesome_outlined,
            title: 'Analisis belum dapat dimuat',
            message: 'Laporan angka tetap dapat digunakan. Coba lagi nanti.',
          ),
          data: (insight) =>
              _InsightContent(insight: insight, compact: compact),
        );
        if (compact || month == null) return content;
        return Column(
          children: [
            _MonthNavigator(month: month!, onChanged: onMonthChanged),
            const SizedBox(height: AppSpacing.sm),
            content,
            if (value.canManage)
              TextButton(
                onPressed: () => _disable(context, ref),
                child: const Text('Nonaktifkan Insight AI'),
              ),
          ],
        );
      },
    );
  }

  Future<void> _disable(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nonaktifkan Insight AI?'),
        content: const Text(
          'Scheduler berhenti memproses data kelompok dan insight tersimpan tidak akan ditampilkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Nonaktifkan'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await updateAIConsent(ref, false);
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menonaktifkan Insight AI: $error')),
          );
        }
      }
    }
  }
}

class _ConsentCard extends ConsumerWidget {
  const _ConsentCard({required this.consent});
  final AIConsent consent;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Insight AI bulanan',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Gemini menganalisis tanggal, kategori, jenis, dan nominal transaksi. Nama, email, catatan, dan ID tidak dikirim.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (!consent.available) ...[
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Gemini belum dikonfigurasi pada server.',
              style: TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
          ] else if (consent.canManage) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _confirm(context, ref),
                icon: const Icon(Icons.shield_outlined),
                label: const Text('Aktifkan dengan persetujuan'),
              ),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Hanya pemilik kelompok yang dapat mengaktifkan fitur ini.',
              style: TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
          ],
        ],
      ),
    ),
  );
  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Aktifkan Insight AI?'),
        content: const Text(
          'Data transaksi tanpa identitas akan dikirim ke Gemini. Pada free tier, Google dapat menggunakan input untuk peningkatan produknya.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Saya setuju'),
          ),
        ],
      ),
    );
    if (accepted == true) {
      try {
        await updateAIConsent(ref, true);
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengaktifkan Insight AI: $error')),
          );
        }
      }
    }
  }
}

class _InsightContent extends StatelessWidget {
  const _InsightContent({required this.insight, required this.compact});
  final FinancialInsight insight;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    // Syaratnya keberadaan analisis, BUKAN statusnya. Selama masih ada hasil
    // tersimpan, tampilkan — walau status 'processing' (sedang diregenerasi
    // karena transaksi bulan itu diedit) atau 'failed'. Menyaring berdasarkan
    // status menyembunyikan analisis lama yang masih valid, dan bila
    // regenerasi gagal permanen hasil itu hilang dari mata pengguna selamanya.
    if (insight.analysis == null) {
      return _MessageCard(
        icon: Icons.schedule_rounded,
        title: _statusTitle(insight.status),
        message: insight.status == 'failed'
            ? 'AI gagal memproses bulan ini dan akan dicoba kembali secara otomatis.'
            : 'Analisis dibuat setelah bulan berakhir.',
      );
    }
    final analysis = insight.analysis!;
    final color = _healthColor(analysis.healthStatus);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: compact ? () => context.go('/reports') : null,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .13),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.auto_awesome_rounded, color: color),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          compact ? 'Insight AI terbaru' : 'Insight AI bulanan',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          // Tandai bahwa isi di bawah adalah hasil lama yang
                          // sedang diperbarui atau gagal diperbarui, supaya
                          // tidak terbaca sebagai analisis terkini.
                          insight.status == 'processing'
                              ? '${insight.period ?? ''} · sedang diperbarui'
                              : insight.status == 'failed'
                              ? '${insight.period ?? ''} · pembaruan gagal'
                              : insight.period ?? '',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(status: analysis.healthStatus, color: color),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                analysis.headline,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                analysis.summary,
                maxLines: compact ? 3 : null,
                overflow: compact ? TextOverflow.ellipsis : null,
              ),
              if (compact) ...[
                const SizedBox(height: AppSpacing.sm),
                ...analysis.recommendations
                    .take(2)
                    .map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.arrow_right_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            Expanded(
                              child: Text(
                                r.action,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ] else ...[
                _Facts(facts: insight.facts),
                if (analysis.keyFindings.isNotEmpty) ...[
                  const _Heading('Temuan utama'),
                  ...analysis.keyFindings.map((v) => _Bullet(v)),
                ],
                if (analysis.recommendations.isNotEmpty) ...[
                  const _Heading('Rekomendasi'),
                  ...analysis.recommendations.map(
                    (v) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(
                        Icons.task_alt_rounded,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        v.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(v.action),
                    ),
                  ),
                ],
                if (analysis.cautions.isNotEmpty) ...[
                  const _Heading('Perlu diperhatikan'),
                  ...analysis.cautions.map(
                    (v) => _Bullet(v, icon: Icons.warning_amber_rounded),
                  ),
                ],
                const Divider(),
                Text(
                  'Insight AI bersifat informatif dan bukan nasihat finansial profesional.${insight.isStale ? ' • Analisis mungkin sudah kedaluwarsa.' : ''}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.textHint),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _statusTitle(String status) => status == 'failed'
      ? 'Analisis gagal'
      : status == 'processing'
      ? 'Sedang dianalisis'
      : 'Belum ada analisis';
}

class _MonthNavigator extends StatelessWidget {
  const _MonthNavigator({required this.month, this.onChanged});
  final DateTime month;
  final ValueChanged<DateTime>? onChanged;
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final last = DateTime(now.year, now.month - 1);
    final canNext =
        month.year < last.year ||
        (month.year == last.year && month.month < last.month);
    const names = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () =>
              onChanged?.call(DateTime(month.year, month.month - 1)),
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          '${names[month.month - 1]} ${month.year}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        IconButton(
          onPressed: canNext
              ? () => onChanged?.call(DateTime(month.year, month.month + 1))
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.facts});
  final InsightFacts facts;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.md),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Fact('Saldo bersih', formatIdr(facts.net)),
        _Fact('Rasio tabungan', '${facts.savingsRate.toStringAsFixed(1)}%'),
        _Fact('Transaksi', '${facts.transactionCount}'),
      ],
    ),
  );
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xs),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text, {this.icon = Icons.circle});
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Icon(
            icon,
            size: icon == Icons.circle ? 7 : 18,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.color});
  final String status;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status == 'good'
          ? 'Baik'
          : status == 'risk'
          ? 'Berisiko'
          : 'Perlu dijaga',
      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
    ),
  );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title, message;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textHint),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(message, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Color _healthColor(String status) => status == 'good'
    ? AppColors.income
    : status == 'risk'
    ? AppColors.expense
    : const Color(0xFFF59E0B);
