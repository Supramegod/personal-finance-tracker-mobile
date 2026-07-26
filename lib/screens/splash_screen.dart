/// SplashScreen — layar pembuka saat app dimulai.
///
/// Cek apakah token JWT tersimpan di flutter_secure_storage.
/// - Jika ada & valid → langsung ke Dashboard
/// - Jika tidak ada / expired → ke LoginScreen
library;

import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_spacing.dart';

/// Layar splash murni tampilan. Redirect ke /login atau /dashboard
/// ditangani oleh GoRouter (lihat app_router.dart) begitu status auth
/// (AuthNotifier._bootstrap) selesai dari `unknown`.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_balance_wallet,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Personal Finance',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              'Tracker',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
