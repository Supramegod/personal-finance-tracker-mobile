import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/repositories/ai_insight_repository.dart';
import 'domain/usecases/get_ai_insight.dart';

final getAIInsightUseCaseProvider = Provider<GetAIInsight>(
  (ref) => GetAIInsight(ref.watch(aiInsightRepositoryProvider)),
);
final manageAIConsentUseCaseProvider = Provider<ManageAIConsent>(
  (ref) => ManageAIConsent(ref.watch(aiInsightRepositoryProvider)),
);

List<Override> registerReportsDependencies() => const [];
