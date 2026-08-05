import '../repositories/auth_repository_contract.dart';

class Logout {
  const Logout(this._repository);
  final AuthRepositoryContract _repository;

  Future<void> call() => _repository.logout();
}
