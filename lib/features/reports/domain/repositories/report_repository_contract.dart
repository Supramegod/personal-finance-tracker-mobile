abstract interface class ReportRepositoryContract {
  Future<Map<String, dynamic>> generate({
    required String period,
    required DateTime from,
    required DateTime to,
  });
}
