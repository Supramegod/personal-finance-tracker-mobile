import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/repositories/auth_repository.dart';
import 'domain/usecases/logout.dart';
import 'presentation/providers/auth_provider.dart';

final logoutUseCaseProvider = Provider<Logout>(
  (ref) => Logout(ref.watch(authRepositoryProvider)),
);

final logoutControllerProvider = Provider<Future<void> Function()>(
  (ref) =>
      () => ref.read(authProvider.notifier).logout(),
);

List<Override> registerAuthDependencies() => const [];
