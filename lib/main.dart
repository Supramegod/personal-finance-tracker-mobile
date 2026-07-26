/// Entry point aplikasi Personal Finance Tracker — Flutter Mobile.
///
/// Setup:
/// 1. ProviderScope (Riverpod)
/// 2. MaterialApp.router (GoRouter)
/// 3. Theme data (Material Design 3 + kustomisasi)
/// 4. Localization (inti.id)
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_router.dart';
import 'core/api/dio_client.dart';
import 'core/constants/app_colors.dart';
import 'providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        // Saat refresh token gagal, interceptor Dio memanggil callback ini
        // untuk menandai sesi berakhir → router redirect ke /login.
        onSessionExpiredProvider.overrideWith(
          (ref) => () => ref.read(authProvider.notifier).onExpired(),
        ),
      ],
      child: const PersonalFinanceApp(),
    ),
  );
}

class PersonalFinanceApp extends ConsumerWidget {
  const PersonalFinanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Personal Finance Tracker',

      // Router
      routerConfig: ref.watch(appRouterProvider),
      
      // Localization
      locale: const Locale('id', 'ID'),
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      // Theme — Light
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.primary,
        brightness: Brightness.light,
        
        // AppBar
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        
        // Card
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        
        // Input
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        
        // Button
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        
        // FAB
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 4,
        ),
        
        // Bottom Nav
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          elevation: 8,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      
      // Theme — Dark
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.primary,
        brightness: Brightness.dark,
        
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        
        cardTheme: CardThemeData(
          elevation: 1,
          color: AppColors.cardBackgroundDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      
      // Default to light theme
      themeMode: ThemeMode.system,
      
      // Debug
      debugShowCheckedModeBanner: false,
    );
  }
}
