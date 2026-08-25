import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/financial_insight.dart';
import '../../domain/repositories/ai_insight_repository_contract.dart';
import '../models/financial_insight_model.dart';

class AIInsightRepository implements AIInsightRepositoryContract {
  const AIInsightRepository(this._dio, this._storage);
  final Dio _dio;
  final TokenStorage _storage;

  @override
  Future<FinancialInsight> getMonth(String month) =>
      _get(ApiEndpoints.aiInsights, query: {'month': month});
  @override
  Future<FinancialInsight> getLatest() => _get(ApiEndpoints.latestAIInsight);
  Future<FinancialInsight> _get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: query,
      );
      return FinancialInsightModel.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<AIConsent> getConsent() async {
    final id = await _requiredGroupId();
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.groupAIConsent(id),
      );
      final data = response.data ?? const {};
      return AIConsent(
        enabled: data['enabled'] as bool? ?? false,
        canManage: data['can_manage'] as bool? ?? false,
        available: data['available'] as bool? ?? false,
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<AIConsent> setConsent(bool enabled) async {
    final id = await _requiredGroupId();
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.groupAIConsent(id),
        data: {'enabled': enabled},
      );
      final data = response.data ?? const {};
      return AIConsent(
        enabled: data['enabled'] as bool? ?? false,
        canManage: data['can_manage'] as bool? ?? false,
        available: data['available'] as bool? ?? false,
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// Meminta backend membuat ulang analisis satu bulan.
  ///
  /// Backend membalas 202 dan bekerja di latar, jadi tidak ada isi yang perlu
  /// dibaca. Penolakan yang wajar terjadi — 403 bukan owner, 409 sedang
  /// berjalan, 429 terlalu cepat — sudah membawa pesan siap tampil di body,
  /// dan ApiException.fromDio yang mengambilnya.
  @override
  Future<void> regenerate(String month) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.regenerateAIInsight,
        queryParameters: {'month': month},
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<String> _requiredGroupId() async {
    final id = await _storage.activeGroupId;
    if (id == null || id.isEmpty)
      throw StateError('Kelompok aktif tidak ditemukan');
    return id;
  }
}

final aiInsightRepositoryProvider = Provider<AIInsightRepositoryContract>(
  (ref) => AIInsightRepository(
    ref.watch(dioProvider),
    ref.watch(tokenStorageProvider),
  ),
);
