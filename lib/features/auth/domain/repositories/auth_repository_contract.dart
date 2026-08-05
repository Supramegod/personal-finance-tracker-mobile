abstract interface class AuthRepositoryContract {
  Future<Map<String, dynamic>> login(String email, String password);
  Future<void> logout();
  Future<bool> hasSession();
}
