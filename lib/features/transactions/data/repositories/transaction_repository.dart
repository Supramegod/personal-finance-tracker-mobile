/// Data repository transaksi: list, create, update, dan delete.
///
/// Envelope list backend: `{data, total, page, limit}`. Filter yang didukung
/// server: type, category_id, from, to (YYYY-MM-DD), page, limit.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository_contract.dart';

class TransactionRepository implements TransactionRepositoryContract {
  TransactionRepository(this._dio);

  final Dio _dio;

  @override
  Future<TransactionListResponse> list({
    int page = 1,
    int limit = 20,
    TransactionType? type,
    String? categoryId,
    DateTime? from,
    DateTime? to,
    String? search,
  }) async {
    String? ymd(DateTime? d) =>
        d == null ? null : d.toIso8601String().substring(0, 10);

    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (type != null) 'type': type.apiValue,
      if (categoryId != null) 'category_id': categoryId,
      if (from != null) 'from': ymd(from),
      if (to != null) 'to': ymd(to),
      if (search != null && search.isNotEmpty) 'search': search,
    };

    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.transactions,
        queryParameters: query,
      );
      return TransactionListResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Transaction> create(Transaction tx) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.transactions,
        data: tx.toJson(),
      );
      return Transaction.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Transaction> update(String id, Transaction tx) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.transaction(id),
        data: tx.toJson(),
      );
      return Transaction.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>(ApiEndpoints.transaction(id));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final transactionRepositoryProvider = Provider<TransactionRepositoryContract>((
  ref,
) {
  return TransactionRepository(ref.watch(dioProvider));
});
