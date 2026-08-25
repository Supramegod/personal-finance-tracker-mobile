import '../entities/financial_insight.dart';

abstract interface class AIInsightRepositoryContract {
  Future<FinancialInsight> getMonth(String month);
  Future<FinancialInsight> getLatest();
  Future<AIConsent> getConsent();
  Future<AIConsent> setConsent(bool enabled);
  Future<void> regenerate(String month);
}
