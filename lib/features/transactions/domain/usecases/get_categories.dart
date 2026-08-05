import '../entities/category.dart';
import '../repositories/category_repository_contract.dart';

class GetCategories {
  const GetCategories(this._repository);
  final CategoryRepositoryContract _repository;

  Future<List<Category>> call() => _repository.list();
}
