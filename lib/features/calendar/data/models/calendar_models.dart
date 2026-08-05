import '../../domain/entities/calendar_day.dart';

class CalendarDayModel {
  const CalendarDayModel({
    required this.date,
    required this.income,
    required this.expense,
    required this.count,
  });

  final String date;
  final double income;
  final double expense;
  final int count;

  factory CalendarDayModel.fromJson(Map<String, dynamic> json) =>
      CalendarDayModel(
        date: json['date'] as String? ?? '',
        income: _number(json['total_income'] ?? json['income']),
        expense: _number(json['total_expense'] ?? json['expense']),
        count: (json['count'] as num?)?.toInt() ?? 0,
      );

  CalendarDay toEntity() =>
      CalendarDay(date: date, income: income, expense: expense, count: count);
}

class CalendarTransactionModel {
  const CalendarTransactionModel({
    required this.type,
    required this.amount,
    required this.categoryName,
    this.note,
  });

  final String type;
  final double amount;
  final String categoryName;
  final String? note;

  factory CalendarTransactionModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    return CalendarTransactionModel(
      type: json['type'] as String? ?? 'expense',
      amount: _number(json['amount']),
      categoryName:
          json['category_name'] as String? ??
          (category is Map ? category['name'] as String? : null) ??
          'Kategori',
      note: json['note'] as String?,
    );
  }

  CalendarTransaction toEntity() => CalendarTransaction(
    type: type,
    amount: amount,
    categoryName: categoryName,
    note: note,
  );
}

double _number(dynamic value) => double.tryParse('${value ?? 0}') ?? 0;
