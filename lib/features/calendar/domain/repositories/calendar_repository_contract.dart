import '../entities/calendar_day.dart';

abstract interface class CalendarRepositoryContract {
  Future<List<CalendarDay>> getMonth(DateTime month);
  Future<List<CalendarTransaction>> getDay(DateTime date);
}
