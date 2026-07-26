/// Repository kategori. Backend membalas `{"data": [...]}`.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_exception.dart';
import '../core/api/dio_client.dart';
import '../core/constants/api_endpoints.dart';
import '../models/category.dart';

class CategoryRepository {
  CategoryRepository(this._dio);

  final Dio _dio;

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

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(dioProvider));
});
