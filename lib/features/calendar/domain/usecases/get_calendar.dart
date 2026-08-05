import '../entities/calendar_day.dart';
import '../repositories/calendar_repository_contract.dart';

class GetCalendar {
  const GetCalendar(this._repository);
  final CalendarRepositoryContract _repository;

  Future<List<CalendarDay>> call(DateTime month) => _repository.getMonth(month);
}

class GetDayTransactions {
  const GetDayTransactions(this._repository);
  final CalendarRepositoryContract _repository;

  Future<List<CalendarTransaction>> call(DateTime date) =>
      _repository.getDay(date);
}
