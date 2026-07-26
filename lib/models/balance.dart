/// Model saldo dan ringkasan keuangan.
///
/// Saldo dihitung sebagai: total_income - total_expense.
/// Tidak ada kolom saldo statis — selalu dihitung dari server.
library;

class Balance {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final String period;
  final String currency;

  const Balance({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.period,
    this.currency = 'IDR',
  });

  factory Balance.fromJson(Map<String, dynamic> json) {
    return Balance(
      totalIncome: double.parse(json['total_income'].toString()),
      totalExpense: double.parse(json['total_expense'].toString()),
      balance: double.parse(json['balance'].toString()),
      period: json['period'] as String? ?? '',
      currency: json['currency'] as String? ?? 'IDR',
    );
  }
}

/// Ringkasan untuk dashboard: saldo total (dari /summary/balance) plus
/// total pemasukan & pengeluaran periode berjalan (dari /summary/report).
/// Backend memisah dua endpoint, jadi model ini menggabungkannya.
class DashboardSummary {
  final double balance;
  final double totalIncome;
  final double totalExpense;

  const DashboardSummary({
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
  });

  static const empty = DashboardSummary(
    balance: 0,
    totalIncome: 0,
    totalExpense: 0,
  );
}

/// Ringkasan income vs expense per periode (harian/mingguan/bulanan).
class MonthlySummary {
  final String period;
  final double incomeTotal;
  final double expenseTotal;
  final String periodLabel;

  const MonthlySummary({
    required this.period,
    required this.incomeTotal,
    required this.expenseTotal,
    required this.periodLabel,
  });

  double get balance => incomeTotal - expenseTotal;

  factory MonthlySummary.fromJson(Map<String, dynamic> json) {
    return MonthlySummary(
      period: json['period'] as String? ?? '',
      incomeTotal: double.parse(json['income_total'].toString()),
      expenseTotal: double.parse(json['expense_total'].toString()),
      periodLabel: json['period_label'] as String? ?? '',
    );
  }
}
