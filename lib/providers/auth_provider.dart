/// State autentikasi global + AuthNotifier.
///
/// GoRouter menyimak provider ini untuk redirect: `unknown` → splash,
/// `unauthenticated` → /login, `authenticated` → /dashboard.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final AuthStatus status;
  final bool isSubmitting;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthState()) {
    _bootstrap();
  }

  final AuthRepository _repo;

  /// Cek sesi tersimpan saat app dibuka.
  Future<void> _bootstrap() async {
    final has = await _repo.hasSession();
    state = state.copyWith(
      status: has ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    );
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repo.login(email, password);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        isSubmitting: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = state.copyWith(status: AuthStatus.unauthenticated, clearError: true);
  }

  /// Dipanggil interceptor Dio saat refresh gagal (sesi kedaluwarsa).
  void onExpired() {
    if (state.status != AuthStatus.unauthenticated) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
