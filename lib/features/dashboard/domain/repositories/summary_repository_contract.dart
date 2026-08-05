import '../entities/balance.dart';

abstract interface class SummaryRepositoryContract {
  Future<DashboardSummary> dashboard();
  Future<List<MonthlySummary>> report({String period});
}
