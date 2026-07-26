/// Provider daftar kategori (dipakai form transaksi & picker).
/// Di-cache selama sesi; refresh manual dengan ref.invalidate.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../repositories/category_repository.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.watch(categoryRepositoryProvider).list();
});
