class AIConsent {
  const AIConsent({
    required this.enabled,
    required this.canManage,
    required this.available,
  });
  final bool enabled;
  final bool canManage;
  final bool available;
}

class InsightFacts {
  const InsightFacts({
    this.totalIncome = 0,
    this.totalExpense = 0,
    this.net = 0,
    this.savingsRate = 0,
    this.expenseChange,
    this.transactionCount = 0,
    this.topCategories = const [],
  });
  final double totalIncome;
  final double totalExpense;
  final double net;
  final double savingsRate;
  final double? expenseChange;
  final int transactionCount;
  final List<InsightCategory> topCategories;
}

class InsightCategory {
  const InsightCategory({
    required this.name,
    required this.amount,
    required this.share,
  });
  final String name;
  final double amount;
  final double share;
}

class InsightRecommendation {
  const InsightRecommendation({
    required this.title,
    required this.action,
    required this.priority,
  });
  final String title;
  final String action;
  final String priority;
}

class InsightAnalysis {
  const InsightAnalysis({
    required this.headline,
    required this.summary,
    required this.healthStatus,
    required this.keyFindings,
    required this.recommendations,
    required this.cautions,
  });
  final String headline;
  final String summary;
  final String healthStatus;
  final List<String> keyFindings;
  final List<InsightRecommendation> recommendations;
  final List<String> cautions;
}

class FinancialInsight {
  const FinancialInsight({
    required this.status,
    this.period,
    this.facts = const InsightFacts(),
    this.analysis,
    this.generatedAt,
    this.model = '',
    this.isStale = false,
    this.error,
  });
  final String status;
  final String? period;
  final InsightFacts facts;
  final InsightAnalysis? analysis;
  final DateTime? generatedAt;
  final String model;
  final bool isStale;
  final String? error;
  bool get isCompleted => status == 'completed' && analysis != null;
}
