import '../entities/financial_insight.dart';
import '../repositories/ai_insight_repository_contract.dart';

class GetAIInsight {
  const GetAIInsight(this.repository);
  final AIInsightRepositoryContract repository;
  Future<FinancialInsight> month(String value) => repository.getMonth(value);
  Future<FinancialInsight> latest() => repository.getLatest();
  Future<void> regenerate(String value) => repository.regenerate(value);
}

class ManageAIConsent {
  const ManageAIConsent(this.repository);
  final AIInsightRepositoryContract repository;
  Future<AIConsent> get() => repository.getConsent();
  Future<AIConsent> set(bool value) => repository.setConsent(value);
}
