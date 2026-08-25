import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/generate_report.dart';
import '../../data/repositories/report_repository.dart';
import '../../domain/entities/financial_insight.dart';
import '../../reports_di.dart';

final generateReportProvider = Provider<GenerateReport>(
  // Report presentation dependency.
  (ref) => GenerateReport(ref.watch(reportRepositoryProvider)),
);

final aiConsentProvider = FutureProvider<AIConsent>(
  (ref) => ref.watch(manageAIConsentUseCaseProvider).get(),
);
final aiInsightProvider = FutureProvider.autoDispose
    .family<FinancialInsight, String>(
      (ref, month) => ref.watch(getAIInsightUseCaseProvider).month(month),
    );
final latestAIInsightProvider = FutureProvider.autoDispose<FinancialInsight>(
  (ref) => ref.watch(getAIInsightUseCaseProvider).latest(),
);

/// Memicu pembuatan ulang analisis, lalu memuat ulang providernya.
///
/// Backend membalas 202 dan bekerja di latar. Baris insight sudah diturunkan
/// ke 'pending' di sisi server, jadi pemuatan ulang di sini menampilkan status
/// terbaru; analisis lama tetap terlihat sampai yang baru selesai.
Future<void> regenerateAIInsight(WidgetRef ref, String month) async {
  await ref.read(getAIInsightUseCaseProvider).regenerate(month);
  ref.invalidate(aiInsightProvider);
  ref.invalidate(latestAIInsightProvider);
}

Future<void> updateAIConsent(WidgetRef ref, bool enabled) async {
  await ref.read(manageAIConsentUseCaseProvider).set(enabled);
  ref.invalidate(aiConsentProvider);
  ref.invalidate(aiInsightProvider);
  ref.invalidate(latestAIInsightProvider);
}
