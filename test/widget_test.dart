import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personaltracker/core/constants/app_colors.dart';
import 'package:personaltracker/core/theme/app_theme.dart';
import 'package:personaltracker/features/calendar/data/models/calendar_models.dart';
import 'package:personaltracker/features/groups/presentation/providers/group_provider.dart';
import 'package:personaltracker/features/more/presentation/pages/more_screen.dart';
import 'package:personaltracker/features/reports/data/models/financial_insight_model.dart';
import 'package:personaltracker/features/settings/presentation/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tema default adalah gelap dan preferensi tersimpan', () async {
    SharedPreferences.setMockInitialValues({});
    final notifier = ThemeNotifier();
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state, AppThemeMode.dark);

    await notifier.setMode(AppThemeMode.light);
    expect(notifier.state, AppThemeMode.light);
    expect(
      (await SharedPreferences.getInstance()).getString('app_theme_mode'),
      'light',
    );
  });

  test('ringkasan kalender membaca field total dari backend', () {
    final day = CalendarDayModel.fromJson({
      'date': '2026-08-05',
      'total_income': 250000,
      'total_expense': 75000,
    }).toEntity();

    expect(day.hasIncome, isTrue);
    expect(day.hasExpense, isTrue);
    expect(day.income, 250000);
    expect(day.expense, 75000);
  });

  test('insight AI membaca structured response backend', () {
    final insight = FinancialInsightModel.fromJson({
      'status': 'completed',
      'period': '2026-07',
      'facts': {
        'total_income': 5000000,
        'total_expense': 3000000,
        'net': 2000000,
        'savings_rate_percent': 40,
        'transaction_count': 12,
      },
      'analysis': {
        'headline': 'Arus kas sehat',
        'summary': 'Pengeluaran masih terkendali.',
        'health_status': 'good',
        'key_findings': ['Saldo positif'],
        'recommendations': [
          {
            'title': 'Pertahankan',
            'action': 'Tinjau mingguan',
            'priority': 'low',
          },
        ],
        'cautions': <String>[],
      },
      'model': 'gemini-2.5-flash-lite',
    });

    expect(insight.isCompleted, isTrue);
    expect(insight.facts.net, 2000000);
    expect(insight.analysis!.recommendations.single.priority, 'low');
  });

  testWidgets('halaman Lainnya menampilkan semua tujuan sekunder', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [groupProvider.overrideWith((ref) => GroupNotifier.test())],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          home: const MoreScreen(),
        ),
      ),
    );

    expect(find.text('Cicilan'), findsOneWidget);
    expect(find.text('Kalender'), findsOneWidget);
    expect(find.text('Kelola Anggota'), findsOneWidget);
    expect(find.text('Pengaturan'), findsOneWidget);
    expect(AppTheme.dark.scaffoldBackgroundColor, AppColors.backgroundDark);
  });
}
