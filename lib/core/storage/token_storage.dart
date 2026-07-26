/// Penyimpanan token JWT (access + refresh) di flutter_secure_storage.
///
/// Konvensi proyek: token WAJIB di secure storage, bukan SharedPreferences.
/// Access token dipakai per-request (Bearer), refresh token dipakai saat
/// access token kedaluwarsa (silent refresh).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kActiveGroup = 'active_group_id';

  Future<String?> get accessToken => _storage.read(key: _kAccess);
  Future<String?> get refreshToken => _storage.read(key: _kRefresh);
  Future<String?> get activeGroupId => _storage.read(key: _kActiveGroup);

  Future<void> saveTokens({
    required String access,
    required String refresh,
    String? activeGroupId,
  }) async {
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kRefresh, value: refresh);
    if (activeGroupId != null) {
      await _storage.write(key: _kActiveGroup, value: activeGroupId);
    }
  }

  Future<void> saveAccessToken(String access) =>
      _storage.write(key: _kAccess, value: access);

  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kActiveGroup);
  }

  Future<bool> get hasSession async => (await accessToken) != null;
}

/// Instance FlutterSecureStorage tunggal untuk seluruh app.
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(ref.watch(secureStorageProvider));
});
