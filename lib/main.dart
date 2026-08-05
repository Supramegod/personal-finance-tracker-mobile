/// Bootstrap aplikasi Personal Finance Tracker.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/di/dependency_injection.dart';
import 'core/api/dio_client.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        ...buildDependencyOverrides(),
        // Saat refresh token gagal, interceptor Dio memanggil callback ini
        // untuk menandai sesi berakhir → router redirect ke /login.
        onSessionExpiredProvider.overrideWith(
          (ref) =>
              () => ref.read(authProvider.notifier).onExpired(),
        ),
      ],
      child: const PersonalFinanceApp(),
    ),
  );
}
