/// Repository tabungan — CRUD pot, setor/tarik, dan pembatalan mutasi.
///
/// Semua request lewat Dio dari [dioProvider] (jangan membuat instance Dio
/// baru: timeout, header auth, dan refresh token silent ada di sana).
/// DioException dikonversi jadi [ApiException] supaya UI menerima pesan
/// Bahasa Indonesia yang siap tampil.
library; // Savings data repository.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/savings_entry.dart';
import '../../domain/entities/savings_goal.dart';
import '../../domain/repositories/savings_repository_contract.dart';

class SavingsRepository implements SavingsRepositoryContract {
  SavingsRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<SavingsGoal>> list({String status = ''}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.savings,
        queryParameters: status.isEmpty ? null : {'status': status},
      );
      final data = res.data?['data'] as List<dynamic>? ?? const [];
      return data
          .map((e) => SavingsGoal.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<({SavingsGoal goal, List<SavingsEntry> entries})> detail(
    String id,
  ) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.savingsDetail(id),
      );
      final data = res.data ?? const <String, dynamic>{};
      final entries = (data['entries'] as List<dynamic>? ?? const [])
          .map((e) => SavingsEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      return (
        goal: SavingsGoal.fromJson(data['goal'] as Map<String, dynamic>),
        entries: entries,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<SavingsGoal> create({
    required String name,
    double? targetAmount,
    String? targetDate,
    String? note,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.savings,
        data: _goalPayload(
          name: name,
          targetAmount: targetAmount,
          targetDate: targetDate,
          note: note,
        ),
      );
      return SavingsGoal.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<SavingsGoal> update({
    required String id,
    required String name,
    double? targetAmount,
    String? targetDate,
    String? note,
    String? status,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.savingsDetail(id),
        data: {
          ..._goalPayload(
            name: name,
            targetAmount: targetAmount,
            targetDate: targetDate,
            note: note,
          ),
          if (status != null) 'status': status,
        },
      );
      return SavingsGoal.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>(ApiEndpoints.savingsDetail(id));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> deposit({
    required String id,
    required double amount,
    String? date,
    String? note,
  }) => _entry(ApiEndpoints.savingsDeposit(id), amount, date, note);

  @override
  Future<void> withdraw({
    required String id,
    required double amount,
    String? date,
    String? note,
  }) => _entry(ApiEndpoints.savingsWithdraw(id), amount, date, note);

  @override
  Future<void> deleteEntry({
    required String id,
    required String entryId,
  }) async {
    try {
      await _dio.delete<void>(ApiEndpoints.savingsEntry(id, entryId));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> _entry(
    String path,
    double amount,
    String? date,
    String? note,
  ) async {
    try {
      await _dio.post<void>(
        path,
        data: {
          'amount': amount,
          if (date != null && date.isNotEmpty) 'date': date,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// target_amount dikirim null saat kosong supaya backend menyimpannya
  /// sebagai NULL (pot tanpa target), bukan 0 yang akan ditolak validasi.
  Map<String, dynamic> _goalPayload({
    required String name,
    double? targetAmount,
    String? targetDate,
    String? note,
  }) => {
    'name': name,
    'target_amount': targetAmount,
    'target_date': targetDate ?? '',
    'note': note ?? '',
  };
}

final savingsRepositoryProvider = Provider<SavingsRepositoryContract>((ref) {
  return SavingsRepository(ref.watch(dioProvider));
});
