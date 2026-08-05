class CalendarDay {
  const CalendarDay({
    required this.date,
    required this.income,
    required this.expense,
    required this.count,
  });

  final String date;
  final double income;
  final double expense;
  final int count;

  bool get hasTransaction => count > 0 || income > 0 || expense > 0;
  bool get hasIncome => income > 0;
  bool get hasExpense => expense > 0;
}

class CalendarTransaction {
  const CalendarTransaction({
    required this.type,
    required this.amount,
    required this.categoryName,
    this.note,
  });

  final String type;
  final double amount;
  final String categoryName;
  final String? note;

  bool get isIncome => type == 'income';
}
