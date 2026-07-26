/// Provider ringkasan dashboard (saldo + income/expense bulan berjalan).
/// autoDispose supaya refetch saat kembali ke dashboard.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/balance.dart';
import '../repositories/summary_repository.dart';

final dashboardSummaryProvider =
    FutureProvider.autoDispose<DashboardSummary>((ref) async {
  return ref.watch(summaryRepositoryProvider).dashboard();
});
