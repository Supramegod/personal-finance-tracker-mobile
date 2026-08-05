import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../domain/repositories/report_repository_contract.dart';

class ReportRepository implements ReportRepositoryContract {
  const ReportRepository(this._dio);
  final Dio _dio;

  @override
  Future<Map<String, dynamic>> generate({
    required String period,
    required DateTime from,
    required DateTime to,
  }) async {
    String ymd(DateTime date) =>
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.report,
        queryParameters: {'period': period, 'from': ymd(from), 'to': ymd(to)},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

final reportRepositoryProvider = Provider<ReportRepositoryContract>(
  (ref) => ReportRepository(ref.watch(dioProvider)),
);
