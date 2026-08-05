import '../repositories/report_repository_contract.dart';

class GenerateReport {
  const GenerateReport(this._repository);
  final ReportRepositoryContract _repository;

  Future<Map<String, dynamic>> call({
    required String period,
    required DateTime from,
    required DateTime to,
  }) => _repository.generate(period: period, from: from, to: to);
}
