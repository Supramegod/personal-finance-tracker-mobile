library; // Reports presentation page.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/report_provider.dart';
import '../widgets/ai_insight_panel.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  String _period = 'monthly';
  DateTimeRange? _dateRange;
  Map<String, dynamic>? _report;
  bool _loading = false;
  String? _error;
  late DateTime _insightMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _insightMonth = DateTime(now.year, now.month - 1);
  }

  Future<void> _fetch() async {
    if (_dateRange == null) {
      setState(() => _error = 'Pilih rentang tanggal terlebih dahulu');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final report = await ref.read(generateReportProvider)(
        period: _period,
        from: _dateRange!.start,
        to: _dateRange!.end,
      );
      setState(() {
        _report = report;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: [
          Text(
            'Analisis keuangan',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Bandingkan pemasukan dan pengeluaran pada periode pilihan.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: .65),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AIInsightPanel(
            month: _insightMonth,
            onMonthChanged: (value) => setState(() => _insightMonth = value),
          ),
          const SizedBox(height: AppSpacing.xl),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'monthly', label: Text('Bulanan')),
                ButtonSegment(value: 'weekly', label: Text('Mingguan')),
                ButtonSegment(value: 'daily', label: Text('Harian')),
              ],
              selected: {_period},
              onSelectionChanged: (v) => setState(() => _period = v.first),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InkWell(
            onTap: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                locale: const Locale('id', 'ID'),
                initialDateRange: _dateRange,
              );
              if (range != null) setState(() => _dateRange = range);
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Rentang Tanggal',
                prefixIcon: Icon(Icons.date_range),
              ),
              child: Text(
                _dateRange != null
                    ? '${formatDate(_dateRange!.start)} - ${formatDate(_dateRange!.end)}'
                    : 'Pilih rentang tanggal',
                style: TextStyle(
                  color: _dateRange != null
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: .5),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: AppSpacing.buttonHeight,
            child: ElevatedButton(
              onPressed: _loading ? null : _fetch,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Tampilkan laporan'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_error != null)
            Card(
              color: AppColors.expense.withValues(alpha: .10),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.expense),
                ),
              ),
            ),
          if (_report != null) ...[
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Pemasukan',
                    amount: double.parse(
                      (_report!['total_income'] ?? 0).toString(),
                    ),
                    color: AppColors.income,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _SummaryCard(
                    label: 'Pengeluaran',
                    amount: double.parse(
                      (_report!['total_expense'] ?? 0).toString(),
                    ),
                    color: AppColors.expense,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Saldo Bersih',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      formatIdr(
                        double.parse((_report!['net'] ?? 0).toString()),
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color:
                            (double.parse((_report!['net'] ?? 0).toString()) >=
                                0)
                            ? AppColors.income
                            : AppColors.expense,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Per Periode',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...((_report!['periods'] as List<dynamic>?) ?? []).map((p) {
              final m = p as Map<String, dynamic>;
              final income = double.parse((m['total_income'] ?? 0).toString());
              final expense = double.parse(
                (m['total_expense'] ?? 0).toString(),
              );
              final periodLabel = m['period']?.toString() ?? '';
              return Card(
                child: ListTile(
                  title: Text(
                    formatPeriodLabel(periodLabel),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Row(
                    children: [
                      Text(
                        '+${formatIdr(income)}',
                        style: const TextStyle(
                          color: AppColors.income,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '-${formatIdr(expense)}',
                        style: const TextStyle(
                          color: AppColors.expense,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: Text(
                    formatIdr(income - expense),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: (income - expense) >= 0
                          ? AppColors.income
                          : AppColors.expense,
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: color)),
            const SizedBox(height: 4),
            Text(
              formatIdr(amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
