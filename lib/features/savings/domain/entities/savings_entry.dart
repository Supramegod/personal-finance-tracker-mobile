/// Satu mutasi tabungan: setoran atau penarikan.
///
/// [transactionId] menunjuk transaksi bertanda transfer yang tercipta bersama
/// mutasi ini. Membatalkan mutasi lewat endpoint tabungan akan menghapus
/// keduanya sekaligus — transaksinya tidak bisa dihapus dari halaman Transaksi.
library; // Savings entry domain entity.

enum SavingsDirection { deposit, withdraw }

class SavingsEntry {
  const SavingsEntry({
    required this.id,
    required this.goalId,
    required this.direction,
    required this.amount,
    required this.entryDate,
    this.transactionId,
    this.note,
  });

  final String id;
  final String goalId;
  final SavingsDirection direction;
  final double amount;
  final DateTime entryDate;
  final String? transactionId;
  final String? note;

  bool get isDeposit => direction == SavingsDirection.deposit;

  factory SavingsEntry.fromJson(Map<String, dynamic> json) {
    return SavingsEntry(
      id: json['id'] as String,
      goalId: json['goal_id'] as String? ?? '',
      direction: json['direction'] == 'withdraw'
          ? SavingsDirection.withdraw
          : SavingsDirection.deposit,
      amount: double.parse((json['amount'] ?? 0).toString()),
      entryDate: json['entry_date'] != null
          ? DateTime.parse(json['entry_date'] as String)
          : DateTime.now(),
      transactionId: json['transaction_id'] as String?,
      note: json['note'] as String?,
    );
  }
}
