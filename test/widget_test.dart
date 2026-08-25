import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personaltracker/core/api/api_exception.dart';
import 'package:personaltracker/core/constants/app_colors.dart';
import 'package:personaltracker/core/theme/app_theme.dart';
import 'package:personaltracker/features/calendar/data/models/calendar_models.dart';
import 'package:personaltracker/features/groups/presentation/providers/group_provider.dart';
import 'package:personaltracker/features/more/presentation/pages/more_screen.dart';
import 'package:personaltracker/core/utils/idr_input_formatter.dart';
import 'package:personaltracker/features/reports/data/models/financial_insight_model.dart';
import 'package:personaltracker/features/savings/data/repositories/savings_repository.dart';
import 'package:personaltracker/features/savings/domain/entities/savings_entry.dart';
import 'package:personaltracker/features/savings/domain/entities/savings_goal.dart';
import 'package:personaltracker/features/savings/domain/repositories/savings_repository_contract.dart';
import 'package:personaltracker/features/savings/presentation/pages/savings_page.dart';
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
    expect(find.text('Tabungan'), findsOneWidget);
    expect(find.text('Kalender'), findsOneWidget);
    expect(find.text('Kelola Anggota'), findsOneWidget);

    // Daftar bertambah panjang sejak Tabungan masuk — Pengaturan kini ada di
    // bawah lipatan, dan ListView tidak membangun item di luar viewport.
    await tester.scrollUntilVisible(find.text('Pengaturan'), 200);
    expect(find.text('Pengaturan'), findsOneWidget);
    expect(AppTheme.dark.scaffoldBackgroundColor, AppColors.backgroundDark);
  });

  // ── Tabungan ───────────────────────────────────────────────────────

  test('SavingsGoal membedakan pot tanpa target dari target nol', () {
    final bebas = SavingsGoal.fromJson(const {
      'id': 'g1',
      'name': 'Dana Darurat',
      'saved_amount': 750000,
      'status': 'active',
      'entry_count': 3,
      'target_amount': null,
      'target_date': null,
      'progress': null,
      'remaining_amount': null,
      'months_left': null,
      'suggested_monthly': null,
      'is_on_track': null,
    });

    // null bukan 0: pot tanpa target tidak boleh menampilkan progress bar.
    expect(bebas.hasTarget, isFalse);
    expect(bebas.targetAmount, isNull);
    expect(bebas.progress, isNull);
    expect(bebas.percent, 0);
    expect(bebas.savedAmount, 750000);
    expect(bebas.canWithdraw, isTrue);
  });

  test('SavingsGoal menghitung persen dan mengklem saat target terlampaui', () {
    SavingsGoal withProgress(double progress) => SavingsGoal.fromJson({
      'id': 'g2',
      'name': 'Motor',
      'saved_amount': 1,
      'status': 'active',
      'entry_count': 1,
      'target_amount': 100,
      'progress': progress,
    });

    expect(withProgress(0.75).percent, 75);
    expect(withProgress(0).percent, 0);
    // Diklem: aria/semantics tidak boleh melaporkan nilai di luar 0..100.
    expect(withProgress(1.2).percent, 100);
  });

  test('SavingsEntry memetakan arah mutasi', () {
    final setor = SavingsEntry.fromJson(const {
      'id': 'e1',
      'goal_id': 'g1',
      'direction': 'deposit',
      'amount': 250000,
      'entry_date': '2026-08-09',
    });
    final tarik = SavingsEntry.fromJson(const {
      'id': 'e2',
      'goal_id': 'g1',
      'direction': 'withdraw',
      'amount': 50000,
      'entry_date': '2026-08-09',
    });

    expect(setor.isDeposit, isTrue);
    expect(tarik.direction, SavingsDirection.withdraw);
    expect(tarik.amount, 50000);
  });

  test('input nominal menyisipkan pemisah ribuan dan bisa dibaca balik', () {
    // Inti keluhan: tanpa pemisah, "1500000" harus dihitung nolnya manual.
    expect(formatIdrInput('1500000'), '1.500.000');
    expect(formatIdrInput('250000'), '250.000');
    expect(formatIdrInput(''), '');
    expect(parseIdrInput('1.500.000'), 1500000);
    expect(parseIdrInput('Rp 250.000'), 250000);
    expect(parseIdrInput(''), 0);
  });

  test('IdrInputFormatter menjaga kursor pada digit yang sama', () {
    const formatter = IdrInputFormatter();

    final hasil = formatter.formatEditUpdate(
      const TextEditingValue(text: '1.000.000'),
      const TextEditingValue(
        text: '12.000.000',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );

    expect(hasil.text, '12.000.000');
    // Kursor tetap setelah "12", tidak melompat ke ujung.
    expect(hasil.selection.baseOffset, 2);
  });

  testWidgets('halaman Tabungan menampilkan pot beserta progresnya', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savingsRepositoryProvider.overrideWithValue(
            _FakeSavingsRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          home: const SavingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dana Darurat'), findsOneWidget);
    expect(find.text('Liburan'), findsOneWidget);
    expect(find.text('75% tercapai'), findsOneWidget);
    // Pot tanpa target tidak menampilkan progres sama sekali.
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('progress bar tabungan mengumumkan nominalnya, bukan cuma warna', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savingsRepositoryProvider.overrideWithValue(
            _FakeSavingsRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const SavingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // LinearProgressIndicator sendiri tidak mengumumkan apa pun — tanpa
    // Semantics pembungkusnya, bar ini tak terbaca screen reader.
    expect(find.bySemanticsLabel('Progres tabungan Liburan'), findsOneWidget);

    // Semua tombol harus memenuhi ukuran target sentuh minimum.
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('tombol Tarik nonaktif saat saldo pot masih nol', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savingsRepositoryProvider.overrideWithValue(
            _FakeSavingsRepository(kosong: true),
          ),
        ],
        child: MaterialApp(theme: AppTheme.dark, home: const SavingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    final tarik = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Tarik'),
    );
    // onPressed null (bukan callback kosong) supaya semantics-nya disabled.
    expect(tarik.onPressed, isNull);
  });

  testWidgets('kegagalan memuat menampilkan pesan dan tombol coba lagi', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savingsRepositoryProvider.overrideWithValue(
            _FakeSavingsRepository(gagal: true),
          ),
        ],
        child: MaterialApp(theme: AppTheme.dark, home: const SavingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Saldo tabungan tidak cukup'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);
  });
}

/// Fake diketik ke kontrak, bukan mock Dio — inilah gunanya provider
/// dideklarasikan sebagai `Provider<SavingsRepositoryContract>`.
class _FakeSavingsRepository implements SavingsRepositoryContract {
  _FakeSavingsRepository({this.kosong = false, this.gagal = false});

  final bool kosong;
  final bool gagal;

  @override
  Future<List<SavingsGoal>> list({String status = ''}) async {
    if (gagal) throw ApiException('Saldo tabungan tidak cukup');
    if (kosong) {
      return [
        SavingsGoal.fromJson(const {
          'id': 'g0',
          'name': 'Baru',
          'saved_amount': 0,
          'status': 'active',
          'entry_count': 0,
        }),
      ];
    }
    return [
      SavingsGoal.fromJson(const {
        'id': 'g1',
        'name': 'Dana Darurat',
        'saved_amount': 750000,
        'status': 'active',
        'entry_count': 3,
      }),
      SavingsGoal.fromJson(const {
        'id': 'g2',
        'name': 'Liburan',
        'saved_amount': 7500000,
        'status': 'active',
        'entry_count': 5,
        'target_amount': 10000000,
        'progress': 0.75,
        'remaining_amount': 2500000,
        'months_left': 5,
        'suggested_monthly': 500000,
        'is_on_track': true,
      }),
    ];
  }

  @override
  Future<({SavingsGoal goal, List<SavingsEntry> entries})> detail(String id) =>
      throw UnimplementedError();

  @override
  Future<SavingsGoal> create({
    required String name,
    double? targetAmount,
    String? targetDate,
    String? note,
  }) => throw UnimplementedError();

  @override
  Future<SavingsGoal> update({
    required String id,
    required String name,
    double? targetAmount,
    String? targetDate,
    String? note,
    String? status,
  }) => throw UnimplementedError();

  @override
  Future<void> delete(String id) => throw UnimplementedError();

  @override
  Future<void> deposit({
    required String id,
    required double amount,
    String? date,
    String? note,
  }) => throw UnimplementedError();

  @override
  Future<void> withdraw({
    required String id,
    required double amount,
    String? date,
    String? note,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteEntry({required String id, required String entryId}) =>
      throw UnimplementedError();
}
