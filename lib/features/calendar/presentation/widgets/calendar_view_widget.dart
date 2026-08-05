/// Widget kalender bulanan milik feature calendar.
///
/// Fitur:
/// - Navigasi bulan (prev/next)
/// - Grid 7 kolom (Minggu - Sabtu)
/// - Hari ini di-highlight
/// - Dot indikator untuk hari yang ada transaksi
/// - Tap hari → buka DayTransactionPopup
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/calendar_day.dart';
import '../providers/calendar_provider.dart';
import 'day_transaction_popup.dart';

class CalendarViewWidget extends ConsumerStatefulWidget {
  const CalendarViewWidget({super.key});

  @override
  ConsumerState<CalendarViewWidget> createState() => _CalendarViewWidgetState();
}

class _CalendarViewWidgetState extends ConsumerState<CalendarViewWidget> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  String _monthLabel() {
    const months = [
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
    return '${months[_currentMonth.month - 1]} ${_currentMonth.year}';
  }

  @override
  Widget build(BuildContext context) {
    final calendarAsync = ref.watch(calendarProvider(_currentMonth));
    final days = calendarAsync.valueOrNull ?? [];
    final dayMap = <String, CalendarDay>{};
    for (final d in days) {
      dayMap[d.date] = d;
    }

    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return Card(
      elevation: AppSpacing.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          children: [
            // Header navigasi bulan
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _prevMonth,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Text(
                  _monthLabel(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextMonth,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Header hari
            Row(
              children: ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: .55),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CalendarLegend(color: AppColors.expense, label: 'Pengeluaran'),
                SizedBox(width: AppSpacing.lg),
                _CalendarLegend(color: AppColors.income, label: 'Pemasukan'),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Grid tanggal
            calendarAsync.when(
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (e, _) => SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gagal memuat',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.error),
                      ),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(calendarProvider(_currentMonth)),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (_) {
                final firstDay = DateTime(
                  _currentMonth.year,
                  _currentMonth.month,
                  1,
                );
                final lastDay = DateTime(
                  _currentMonth.year,
                  _currentMonth.month + 1,
                  0,
                );
                final startOffset = firstDay.weekday % 7;
                final totalDays = lastDay.day;
                final totalCells = startOffset + totalDays;

                final cells = <Widget>[];
                for (int i = 0; i < totalCells; i++) {
                  if (i < startOffset) {
                    cells.add(const SizedBox());
                  } else {
                    final day = i - startOffset + 1;
                    final dateStr =
                        '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                    final dayData = dayMap[dateStr];
                    final isToday = dateStr == todayStr;
                    final hasTx = dayData?.hasTransaction ?? false;
                    final isSunday = (i % 7 == 0);

                    cells.add(
                      GestureDetector(
                        onTap: () {
                          if (hasTx) {
                            final selected = DateTime(
                              _currentMonth.year,
                              _currentMonth.month,
                              day,
                            );
                            ref
                                    .read(selectedCalendarDateProvider.notifier)
                                    .state =
                                selected;
                            showDialog(
                              context: context,
                              builder: (_) =>
                                  DayTransactionPopup(date: selected),
                            );
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : null,
                            borderRadius: BorderRadius.circular(6),
                            border: isToday
                                ? Border.all(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isToday
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSunday
                                      ? AppColors.expense
                                      : (isToday
                                            ? AppColors.primary
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurface),
                                ),
                              ),
                              if (hasTx)
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (dayData!.hasExpense)
                                        const _TransactionDot(
                                          color: AppColors.expense,
                                        ),
                                      if (dayData.hasExpense &&
                                          dayData.hasIncome)
                                        const SizedBox(width: 3),
                                      if (dayData.hasIncome)
                                        const _TransactionDot(
                                          color: AppColors.income,
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                }

                return GridView.count(
                  crossAxisCount: 7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.1,
                  children: cells,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionDot extends StatelessWidget {
  const _TransactionDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 7,
    height: 7,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _TransactionDot(color: color),
      const SizedBox(width: 5),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}
