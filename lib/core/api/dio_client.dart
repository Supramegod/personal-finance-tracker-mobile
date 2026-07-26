/// Konfigurasi Dio: base URL, header Bearer otomatis, logging, dan silent
/// refresh saat access token kedaluwarsa (HTTP 401).
///
/// Alur refresh:
/// 1. Request kena 401.
/// 2. Interceptor pakai refresh_token untuk minta token baru ke /auth/refresh.
/// 3. Refresh token bersifat single-use (dirotasi server), maka SIMPAN kedua
///    token baru, lalu ulangi request awal dengan access token baru.
/// 4. Bila refresh gagal → hapus sesi & tandai auth berakhir (redirect ke login).
///
/// Refresh dijaga satu-antrian (`_refreshing`) agar banyak request 401 paralel
/// tidak memicu banyak refresh sekaligus (yang akan saling membatalkan karena
/// rotasi single-use).
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_endpoints.dart';
import '../storage/token_storage.dart';

/// Callback yang dipanggil saat sesi benar-benar berakhir (refresh gagal).
/// Diisi oleh AuthNotifier agar UI bisa redirect ke login.
final onSessionExpiredProvider = Provider<void Function()>((ref) => () {});

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(tokenStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.apiRoot,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Completer<String?>? refreshing;

  Future<String?> doRefresh() async {
    // Bila refresh sedang berjalan, ikut menunggu hasilnya.
    if (refreshing != null) return refreshing!.future;
    refreshing = Completer<String?>();

    try {
      final refreshToken = await storage.refreshToken;
      if (refreshToken == null) {
        refreshing!.complete(null);
        return null;
      }

      // Dio terpisah tanpa interceptor untuk hindari rekursi 401.
      final raw = Dio(BaseOptions(baseUrl: ApiEndpoints.apiRoot));
      final res = await raw.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final data = res.data as Map<String, dynamic>;
      final newAccess = data['access_token'] as String;
      final newRefresh = data['refresh_token'] as String;
      await storage.saveTokens(
        access: newAccess,
        refresh: newRefresh,
        activeGroupId: data['active_group_id'] as String?,
      );
      refreshing!.complete(newAccess);
      return newAccess;
    } catch (_) {
      refreshing!.complete(null);
      return null;
    } finally {
      final done = refreshing;
      refreshing = null;
      // Amankan bila belum sempat complete di jalur tak terduga.
      if (done != null && !done.isCompleted) done.complete(null);
    }
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (kDebugMode) {
          debugPrint('[API] ${options.method} ${options.uri}');
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        final res = e.response;
        final isAuthEndpoint =
            e.requestOptions.path.contains('/auth/');
        // Coba refresh sekali untuk 401 di endpoint non-auth.
        if (res?.statusCode == 401 &&
            !isAuthEndpoint &&
            e.requestOptions.extra['retried'] != true) {
          final newAccess = await doRefresh();
          if (newAccess != null) {
            final opts = e.requestOptions;
            opts.extra['retried'] = true;
            opts.headers['Authorization'] = 'Bearer $newAccess';
            try {
              final clone = await dio.fetch<dynamic>(opts);
              return handler.resolve(clone);
            } catch (err) {
              return handler.next(err as DioException);
            }
          }
          // Refresh gagal → sesi berakhir.
          await storage.clear();
          ref.read(onSessionExpiredProvider)();
        }
        handler.next(e);
      },
    ),
  );

  return dio;
});
