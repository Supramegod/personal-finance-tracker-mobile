/// Widget kartu grafik ringkasan income vs expense.
///
/// Menampilkan bar chart horizontal menggunakan fl_chart.
/// Digunakan di DashboardScreen.
library; // Dashboard summary chart.

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';

class SummaryChartCard extends StatelessWidget {
  final double incomeTotal;
  final double expenseTotal;
  final String periodLabel;

  const SummaryChartCard({
    super.key,
    required this.incomeTotal,
    required this.expenseTotal,
    this.periodLabel = 'Bulan Ini',
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = [
      incomeTotal,
      expenseTotal,
    ].reduce((a, b) => a > b ? a : b);
    final maxDisplay = maxValue > 0 ? maxValue * 1.3 : 100.0; // 30% padding

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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Income vs Expense',
                  style: AppTextStyles.sectionHeader(context),
                ),
                Text(
                  periodLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Bar Chart Horizontal
            SizedBox(
              height: 100,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxDisplay,
                  minY: 0,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final isIncome = groupIndex == 0;
                        return BarTooltipItem(
                          isIncome ? 'Pemasukan' : 'Pengeluaran',
                          TextStyle(
                            color: isIncome
                                ? AppColors.chartIncome
                                : AppColors.chartExpense,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: '\n${formatIdr(rod.toY)}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  'Pemasukan',
                                  style: TextStyle(fontSize: 11),
                                ),
                              );
                            case 1:
                              return const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  'Pengeluaran',
                                  style: TextStyle(fontSize: 11),
                                ),
                              );
                            default:
                              return const SizedBox.shrink();
                          }
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: maxDisplay / 4,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: AppColors.chartGrid, strokeWidth: 1);
                    },
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    _makeBarGroup(0, incomeTotal, AppColors.chartIncome),
                    _makeBarGroup(1, expenseTotal, AppColors.chartExpense),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _LegendItem(
                  color: AppColors.chartIncome,
                  label: 'Pemasukan',
                  amount: formatIdr(incomeTotal),
                ),
                _LegendItem(
                  color: AppColors.chartExpense,
                  label: 'Pengeluaran',
                  amount: formatIdr(expenseTotal),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 32,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String amount;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label $amount',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
