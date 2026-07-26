/// Konfigurasi router aplikasi (GoRouter + Riverpod).
///
/// Redirect berbasis status auth:
/// /splash             → saat status masih `unknown` (cek sesi)
/// /login              → belum login
/// /dashboard,/history → sudah login (di dalam MainScaffold shell)
/// /add-transaction    → form create/edit (push full screen)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'models/transaction.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/main_scaffold.dart';
import 'screens/splash_screen.dart';
import 'screens/transactions/add_transaction_screen.dart';
import 'screens/transactions/transaction_list_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(authProvider).status;
      final loc = state.matchedLocation;

      if (status == AuthStatus.unknown) {
        return loc == '/splash' ? null : '/splash';
      }
      final loggedIn = status == AuthStatus.authenticated;

      if (!loggedIn) {
        return loc == '/login' ? null : '/login';
      }
      // Sudah login tapi masih di gerbang auth → ke dashboard.
      if (loc == '/login' || loc == '/splash') return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/history',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TransactionListScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/add-transaction',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          return AddTransactionScreen(
            transaction: state.extra as Transaction?,
          );
        },
      ),
    ],
  );
});

/// Menjembatani perubahan status auth (Riverpod) ke GoRouter agar redirect
/// dievaluasi ulang saat login/logout/sesi berakhir. Langganan ref.listen
/// otomatis dibersihkan saat provider router di-dispose.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen<AuthState>(
      authProvider,
      (prev, next) {
        if (prev?.status != next.status) notifyListeners();
      },
    );
  }
}
