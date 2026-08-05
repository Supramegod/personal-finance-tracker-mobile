/// Repository autentikasi: login, logout, dan bootstrap sesi.
///
/// Menyimpan token hasil login ke secure storage. Handler 401/refresh
/// ditangani di interceptor Dio (lihat core/api/dio_client.dart).
library; // Auth data repository.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/repositories/auth_repository_contract.dart';

class AuthRepository implements AuthRepositoryContract {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final TokenStorage _storage;

  /// Login → simpan access & refresh token + group aktif. Mengembalikan
  /// LoginResponse mentah (dipakai untuk baca daftar groups bila perlu).
  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      final data = res.data as Map<String, dynamic>;
      await _storage.saveTokens(
        access: data['access_token'] as String,
        refresh: data['refresh_token'] as String,
        activeGroupId: data['active_group_id'] as String?,
      );
      return data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Logout: revoke refresh token di server (best-effort) lalu hapus lokal.
  @override
  Future<void> logout() async {
    final refresh = await _storage.refreshToken;
    try {
      if (refresh != null) {
        await _dio.post<void>(
          ApiEndpoints.logout,
          data: {'refresh_token': refresh},
        );
      }
    } on DioException {
      // Abaikan error server saat logout — yang penting sesi lokal terhapus.
    } finally {
      await _storage.clear();
    }
  }

  @override
  Future<bool> hasSession() => _storage.hasSession;
}

final authRepositoryProvider = Provider<AuthRepositoryContract>((ref) {
  return AuthRepository(
    ref.watch(dioProvider),
    ref.watch(tokenStorageProvider),
  );
});
