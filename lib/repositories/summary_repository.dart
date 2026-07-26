/// Repository ringkasan keuangan.
///
/// Backend memisah dua endpoint:
/// - GET /summary/balance → {"balance": <num>}   (saldo = SUM income - expense)
/// - GET /summary/report?period=monthly → {"periods":[...], "total_income",
///   "total_expense", "net"}
///
/// Untuk dashboard, keduanya digabung jadi satu DashboardSummary.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_exception.dart';
import '../core/api/dio_client.dart';
import '../core/constants/api_endpoints.dart';
import '../models/balance.dart';

class SummaryRepository {
  SummaryRepository(this._dio);

  final Dio _dio;

  Future<DashboardSummary> dashboard() async {
    try {
      final results = await Future.wait([
        _dio.get<Map<String, dynamic>>(ApiEndpoints.balance),
        _dio.get<Map<String, dynamic>>(
          ApiEndpoints.report,
          queryParameters: {'period': 'monthly'},
        ),
      ]);

      final balanceData = results[0].data as Map<String, dynamic>;
      final reportData = results[1].data as Map<String, dynamic>;

      double num2d(dynamic v) => double.parse((v ?? 0).toString());

      return DashboardSummary(
        balance: num2d(balanceData['balance']),
        totalIncome: num2d(reportData['total_income']),
        totalExpense: num2d(reportData['total_expense']),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Laporan per-periode untuk grafik (default bulanan).
  Future<List<MonthlySummary>> report({String period = 'monthly'}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.report,
        queryParameters: {'period': period},
      );
      final data = res.data as Map<String, dynamic>;
      final rows = (data['periods'] as List<dynamic>?) ?? const [];
      return rows.map((e) {
        final m = e as Map<String, dynamic>;
        double num2d(dynamic v) => double.parse((v ?? 0).toString());
        return MonthlySummary(
          period: m['period']?.toString() ?? '',
          incomeTotal: num2d(m['total_income']),
          expenseTotal: num2d(m['total_expense']),
          periodLabel: m['period']?.toString() ?? '',
        );
      }).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final summaryRepositoryProvider = Provider<SummaryRepository>((ref) {
  return SummaryRepository(ref.watch(dioProvider));
});
