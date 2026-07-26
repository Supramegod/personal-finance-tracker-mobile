/// MainScaffold — kerangka utama setelah login (shell GoRouter).
///
/// BottomNavigationBar 3 tab:
/// 0. Dashboard (/dashboard)
/// 1. Catat     → push /add-transaction (bukan tab, aksi)
/// 2. Riwayat   (/history)
///
/// `child` diisi oleh ShellRoute sesuai rute aktif; index tab dihitung
/// dari lokasi rute saat ini.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  int _indexForLocation(String location) {
    if (location.startsWith('/history')) return 2;
    return 0; // default dashboard
  }

  void _onTabTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.push('/add-transaction');
        break;
      case 2:
        context.go('/history');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexForLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onTabTapped(context, index),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline, size: 32),
            activeIcon: Icon(Icons.add_circle, size: 32),
            label: 'Catat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Riwayat',
          ),
        ],
      ),
    );
  }
}
