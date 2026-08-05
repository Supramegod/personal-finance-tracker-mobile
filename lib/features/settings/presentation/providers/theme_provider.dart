import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { dark, light, system } // Settings presentation state.

extension AppThemeModeX on AppThemeMode {
  ThemeMode get material => switch (this) {
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.system => ThemeMode.system,
  };

  String get label => switch (this) {
    AppThemeMode.dark => 'Gelap',
    AppThemeMode.light => 'Terang',
    AppThemeMode.system => 'Ikuti sistem',
  };
}

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  ThemeNotifier() : super(AppThemeMode.dark) {
    _load();
  }

  static const _key = 'app_theme_mode';

  Future<void> _load() async {
    final value = (await SharedPreferences.getInstance()).getString(_key);
    state =
        AppThemeMode.values.where((mode) => mode.name == value).firstOrNull ??
        AppThemeMode.dark;
  }

  Future<void> setMode(AppThemeMode mode) async {
    state = mode;
    await (await SharedPreferences.getInstance()).setString(_key, mode.name);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>(
  (_) => ThemeNotifier(),
);
