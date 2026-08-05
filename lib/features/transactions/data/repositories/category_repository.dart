/// Repository kategori. Backend membalas `{"data": [...]}`.
library; // Transaction category repository.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository_contract.dart';

class CategoryRepository implements CategoryRepositoryContract {
  CategoryRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<Category>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.categories);
      final data = (res.data as Map<String, dynamic>)['data'] as List<dynamic>;
      return data
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final categoryRepositoryProvider = Provider<CategoryRepositoryContract>((ref) {
  return CategoryRepository(ref.watch(dioProvider));
});
