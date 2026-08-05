import '../entities/category.dart';

abstract interface class CategoryRepositoryContract {
  Future<List<Category>> list();
}
