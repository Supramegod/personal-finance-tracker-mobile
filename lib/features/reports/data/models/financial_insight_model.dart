import '../../domain/entities/financial_insight.dart';

class FinancialInsightModel {
  static FinancialInsight fromJson(Map<String, dynamic> json) {
    final facts = _map(json['facts']);
    final analysis = json['analysis'] is Map ? _map(json['analysis']) : null;
    return FinancialInsight(
      status: json['status'] as String? ?? 'not_available',
      period: json['period'] as String?,
      facts: InsightFacts(
        totalIncome: _number(facts['total_income']),
        totalExpense: _number(facts['total_expense']),
        net: _number(facts['net']),
        savingsRate: _number(facts['savings_rate_percent']),
        expenseChange: facts['expense_change_percent'] == null
            ? null
            : _number(facts['expense_change_percent']),
        transactionCount: (facts['transaction_count'] as num?)?.toInt() ?? 0,
        topCategories: _list(facts['top_expense_categories']).map((item) {
          final value = _map(item);
          return InsightCategory(
            name: value['name'] as String? ?? '',
            amount: _number(value['amount']),
            share: _number(value['share_percent']),
          );
        }).toList(),
      ),
      analysis: analysis == null
          ? null
          : InsightAnalysis(
              headline: analysis['headline'] as String? ?? '',
              summary: analysis['summary'] as String? ?? '',
              healthStatus: analysis['health_status'] as String? ?? 'watch',
              keyFindings: _list(
                analysis['key_findings'],
              ).map((e) => e.toString()).toList(),
              recommendations: _list(analysis['recommendations']).map((item) {
                final value = _map(item);
                return InsightRecommendation(
                  title: value['title'] as String? ?? '',
                  action: value['action'] as String? ?? '',
                  priority: value['priority'] as String? ?? 'medium',
                );
              }).toList(),
              cautions: _list(
                analysis['cautions'],
              ).map((e) => e.toString()).toList(),
            ),
      generatedAt: DateTime.tryParse(json['generated_at'] as String? ?? ''),
      model: json['model'] as String? ?? '',
      isStale: json['is_stale'] as bool? ?? false,
      error: json['error'] as String?,
    );
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  static List<dynamic> _list(dynamic value) => value is List ? value : const [];
  static double _number(dynamic value) => double.tryParse('${value ?? 0}') ?? 0;
}
