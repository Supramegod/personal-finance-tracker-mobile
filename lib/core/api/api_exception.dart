/// Pemetaan error jaringan/Dio menjadi pesan yang ramah pengguna (Bahasa
/// Indonesia). Backend membalas error dengan bentuk `{"error": "pesan"}`.
library;

import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;

  /// Ubah DioException menjadi ApiException dengan pesan yang bisa ditampilkan.
  factory ApiException.fromDio(DioException e) {
    // Pesan dari body backend: {"error": "..."} atau {"message": "..."}
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['error'] ?? data['message'];
      if (msg is String && msg.isNotEmpty) {
        return ApiException(msg, statusCode: e.response?.statusCode);
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('Koneksi timeout. Coba lagi.');
      case DioExceptionType.connectionError:
        return ApiException('Tidak dapat terhubung ke server.');
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 401) return ApiException('Sesi berakhir. Silakan login lagi.', statusCode: 401);
        if (code == 403) return ApiException('Akses ditolak.', statusCode: 403);
        if (code == 404) return ApiException('Data tidak ditemukan.', statusCode: 404);
        return ApiException('Terjadi kesalahan server ($code).', statusCode: code);
      default:
        return ApiException('Terjadi kesalahan. Coba lagi.');
    }
  }
}
