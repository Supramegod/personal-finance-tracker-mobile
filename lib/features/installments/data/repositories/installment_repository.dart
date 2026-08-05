/// Repository cicilan — list, create, pay, delete.
///
/// Semua request menggunakan Dio. Error ditangkap dan dikonversi
/// menjadi [ApiException] agar UI bisa menampilkan pesan yang ramah.
library; // Installment data repository.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/dio_client.dart';
import '../../domain/entities/installment.dart';
import '../../domain/repositories/installment_repository_contract.dart';

class InstallmentRepository implements InstallmentRepositoryContract {
  InstallmentRepository(this._dio);
  final Dio _dio;

  @override
  Future<List<Installment>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/installments');
      final data =
          (res.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
      return data
          .map((e) => Installment.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Installment> create({
    required String categoryId,
    required String title,
    required double monthlyAmount,
    required int tenorMonths,
    required String startDate,
    String? note,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/installments',
        data: {
          'category_id': categoryId,
          'title': title,
          'monthly_amount': monthlyAmount,
          'tenor_months': tenorMonths,
          'start_date': startDate,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
      return Installment.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> pay(String id) async {
    try {
      await _dio.post<void>('/installments/$id/pay');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>('/installments/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final installmentRepositoryProvider = Provider<InstallmentRepositoryContract>((
  ref,
) {
  return InstallmentRepository(ref.watch(dioProvider));
});
