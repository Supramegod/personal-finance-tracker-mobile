/// Konfigurasi router aplikasi pada application layer (GoRouter + Riverpod).
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

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/splash_screen.dart';
import '../../features/calendar/presentation/pages/calendar_screen.dart';
import '../../features/dashboard/presentation/pages/dashboard_screen.dart';
import '../../features/groups/presentation/pages/members_page.dart';
import '../../features/installments/presentation/pages/installment_page.dart';
import '../../features/more/presentation/pages/more_screen.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/settings/presentation/pages/settings_screen.dart';
import '../../features/transactions/domain/entities/transaction.dart';
import '../../features/transactions/presentation/pages/add_transaction_screen.dart';
import '../../features/transactions/presentation/pages/transaction_list_screen.dart';
import '../main_navigation/main_scaffold.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
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
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: '/history',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TransactionListScreen()),
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ReportsPage()),
          ),
          GoRoute(
            path: '/more',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MoreScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/installments',
        builder: (_, _) => const InstallmentPage(),
      ),
      GoRoute(path: '/calendar', builder: (_, _) => const CalendarScreen()),
      GoRoute(path: '/members', builder: (_, _) => const MembersPage()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(
        path: '/add-transaction',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          return AddTransactionScreen(transaction: state.extra as Transaction?);
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
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.status != next.status) notifyListeners();
    });
  }
}
