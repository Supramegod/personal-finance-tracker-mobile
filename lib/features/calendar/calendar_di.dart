import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/repositories/calendar_repository.dart';
import 'domain/usecases/get_calendar.dart';

final getCalendarUseCaseProvider = Provider<GetCalendar>(
  (ref) => GetCalendar(ref.watch(calendarRepositoryProvider)),
);

final getDayTransactionsUseCaseProvider = Provider<GetDayTransactions>(
  (ref) => GetDayTransactions(ref.watch(calendarRepositoryProvider)),
);

List<Override> registerCalendarDependencies() => const [];
