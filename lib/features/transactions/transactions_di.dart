import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/repositories/category_repository.dart';
import 'domain/usecases/get_categories.dart';

final getCategoriesUseCaseProvider = Provider<GetCategories>(
  (ref) => GetCategories(ref.watch(categoryRepositoryProvider)),
);

List<Override> registerTransactionsDependencies() => const [];
