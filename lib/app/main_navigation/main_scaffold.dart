/// MainScaffold — application shell utama setelah login.
///
/// Navigasi utama dengan aksi Catat menonjol di tengah seperti tombol QRIS.
///
/// `child` diisi oleh ShellRoute sesuai rute aktif; index tab dihitung
/// dari lokasi rute saat ini.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  int _indexForLocation(String location) {
    if (location.startsWith('/history')) return 1;
    if (location.startsWith('/reports')) return 2;
    if (location.startsWith('/more')) return 3;
    return 0; // default dashboard
  }

  void _onTabTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/history');
        break;
      case 2:
        context.go('/reports');
        break;
      case 3:
        context.go('/more');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexForLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: _FinanceNavigationBar(
        currentIndex: currentIndex,
        onDestinationSelected: (index) => _onTabTapped(context, index),
        onRecord: () => context.push('/add-transaction'),
      ),
    );
  }
}

class _FinanceNavigationBar extends StatelessWidget {
  const _FinanceNavigationBar({
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.onRecord,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: .18),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Row(
            children: [
              _NavItem(
                label: 'Beranda',
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                selected: currentIndex == 0,
                onTap: () => onDestinationSelected(0),
              ),
              _NavItem(
                label: 'Transaksi',
                icon: Icons.receipt_long_outlined,
                selectedIcon: Icons.receipt_long_rounded,
                selected: currentIndex == 1,
                onTap: () => onDestinationSelected(1),
              ),
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Catat transaksi',
                  child: InkWell(
                    onTap: onRecord,
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(17),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: .24,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            color: theme.colorScheme.onPrimary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Catat',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _NavItem(
                label: 'Laporan',
                icon: Icons.bar_chart_outlined,
                selectedIcon: Icons.bar_chart_rounded,
                selected: currentIndex == 2,
                onTap: () => onDestinationSelected(2),
              ),
              _NavItem(
                label: 'Lainnya',
                icon: Icons.grid_view_outlined,
                selectedIcon: Icons.grid_view_rounded,
                selected: currentIndex == 3,
                onTap: () => onDestinationSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: .55);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? selectedIcon : icon, color: color, size: 23),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
