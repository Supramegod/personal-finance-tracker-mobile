import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/calendar_day.dart';
import '../../domain/repositories/calendar_repository_contract.dart';
import '../models/calendar_models.dart';

class CalendarRepository implements CalendarRepositoryContract {
  const CalendarRepository(this._dio);
  final Dio _dio;

  @override
  Future<List<CalendarDay>> getMonth(DateTime month) async {
    final value = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.calendar,
        queryParameters: {'month': value},
      );
      return _items(response.data)
          .map(CalendarDayModel.fromJson)
          .map((model) => model.toEntity())
          .where((day) => day.date.isNotEmpty)
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<List<CalendarTransaction>> getDay(DateTime date) async {
    final value = _ymd(date);
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.transactions,
        queryParameters: {'from': value, 'to': value, 'limit': 100},
      );
      return _items(response.data)
          .map(CalendarTransactionModel.fromJson)
          .map((model) => model.toEntity())
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  static List<Map<String, dynamic>> _items(Map<String, dynamic>? body) =>
      ((body?['data'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();

  static String _ymd(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

final calendarRepositoryProvider = Provider<CalendarRepositoryContract>(
  (ref) => CalendarRepository(ref.watch(dioProvider)),
);
