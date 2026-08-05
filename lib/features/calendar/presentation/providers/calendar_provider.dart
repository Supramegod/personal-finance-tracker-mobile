/// Presentation provider kalender bulanan dan transaksi harian.
///
/// Kalender backend: GET /transactions/calendar?month=YYYY-MM
/// Response: { "data": [ { "date": "2026-06-15", "total_income": 5000000, "total_expense": 1500000 }, ... ] }
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../calendar_di.dart';
import '../../domain/entities/calendar_day.dart';

final selectedCalendarDateProvider = StateProvider<DateTime?>((ref) => null);

/// Provider kalender: ambil data bulanan dari /transactions/calendar
/// Param: DateTime representing any day in the target month
final calendarProvider = FutureProvider.autoDispose
    .family<List<CalendarDay>, DateTime>((ref, month) async {
      return ref.watch(getCalendarUseCaseProvider)(month);
    });

/// Provider transaksi untuk tanggal yang dipilih
final dayTransactionsProvider =
    FutureProvider.family<List<CalendarTransaction>, DateTime>(
      (ref, date) => ref.watch(getDayTransactionsUseCaseProvider)(date),
    );
