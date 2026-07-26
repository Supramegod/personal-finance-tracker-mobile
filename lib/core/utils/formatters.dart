/// Fungsi formatting untuk IDR, tanggal, dan utilitas display lainnya.
///
/// Gunakan fungsi dari sini, jangan format manual di widget.
library;

import 'package:intl/intl.dart';

/// Format jumlah ke mata uang IDR.
///
/// Contoh:
/// ```dart
/// formatIdr(12500000.00) // → 'Rp 12.500.000'
/// formatIdr(35000)       // → 'Rp 35.000'
/// ```
String formatIdr(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}

/// Format jumlah IDR dengan tanda + atau -.
///
/// Contoh:
/// ```dart
/// formatIdrWithSign(8500000, isIncome: true)  // → '+Rp 8.500.000'
/// formatIdrWithSign(35000, isIncome: false)   // → '-Rp 35.000'
/// ```
String formatIdrWithSign(double amount, {required bool isIncome}) {
  final formatted = formatIdr(amount);
  return isIncome ? '+$formatted' : '-$formatted';
}

/// Format tanggal ke format Indonesia.
///
/// Contoh:
/// ```dart
/// formatDate(DateTime(2026, 6, 19)) // → '19 Jun 2026'
/// ```
String formatDate(DateTime date) {
  final formatter = DateFormat('dd MMM yyyy', 'id_ID');
  return formatter.format(date);
}

/// Format tanggal untuk section header (Hari Ini, Kemarin, atau tanggal).
///
/// Contoh:
/// ```dart
/// formatDateRelative(DateTime.now())       // → 'Hari Ini'
/// formatDateRelative(DateTime.now().sub...) // → 'Kemarin'
/// formatDateRelative(someDate)              // → '19 Jun 2026'
/// ```
String formatDateRelative(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);

  final difference = today.difference(target).inDays;

  switch (difference) {
    case 0:
      return 'Hari Ini';
    case 1:
      return 'Kemarin';
    case 2:
    case 3:
    case 4:
    case 5:
    case 6:
      return '$difference Hari Lalu';
    default:
      return formatDate(date);
  }
}

/// Format periode bulan (dari API "2026-06").
///
/// Contoh:
/// ```dart
/// formatPeriodLabel('2026-06') // → 'Juni 2026'
/// ```
String formatPeriodLabel(String period) {
  try {
    final parts = period.split('-');
    if (parts.length != 2) return period;
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final date = DateTime(year, month);
    return DateFormat('MMMM yyyy', 'id_ID').format(date);
  } catch (_) {
    return period;
  }
}
