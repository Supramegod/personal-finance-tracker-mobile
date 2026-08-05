import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../auth/auth_di.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  // Settings presentation page.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(themeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: [
          Text(
            'Tampilan',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Column(
              children: AppThemeMode.values
                  .map(
                    (mode) => ListTile(
                      title: Text(mode.label),
                      leading: Icon(switch (mode) {
                        AppThemeMode.dark => Icons.dark_mode_outlined,
                        AppThemeMode.light => Icons.light_mode_outlined,
                        AppThemeMode.system =>
                          Icons.settings_brightness_outlined,
                      }),
                      trailing: selected == mode
                          ? const Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                            )
                          : const Icon(Icons.circle_outlined),
                      onTap: () =>
                          ref.read(themeProvider.notifier).setMode(mode),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Akun',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: ListTile(
              minTileHeight: 64,
              leading: const Icon(Icons.logout, color: AppColors.expense),
              title: const Text(
                'Keluar',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Akhiri sesi di perangkat ini'),
              onTap: () => _logout(context, ref),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Text(
              'Personal Finance Tracker • v1.0.0',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.logout, color: AppColors.expense),
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Kamu perlu masuk kembali untuk melihat data keuangan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (result == true) await ref.read(logoutControllerProvider)();
  }
}
