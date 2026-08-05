/// Presentation provider ringkasan dashboard bulan berjalan.
/// autoDispose supaya refetch saat kembali ke dashboard.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/balance.dart';
import '../../data/repositories/summary_repository.dart';

final dashboardSummaryProvider = FutureProvider.autoDispose<DashboardSummary>((
  ref,
) async {
  return ref.watch(summaryRepositoryProvider).dashboard();
});
