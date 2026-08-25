/// Pot tabungan beserta nilai turunan yang dihitung server.
///
/// Menabung diperlakukan sebagai TRANSFER, bukan pengeluaran: setoran
/// menurunkan saldo kas dan menaikkan saldo pot, tapi kekayaan bersih tidak
/// berubah. Karena itu mutasinya tidak muncul di laporan pemasukan/pengeluaran.
///
/// Field turunan bernilai null untuk pot tanpa target (mis. dana darurat) —
/// null berbeda artinya dari 0 dan tidak boleh dijadikan 0 saat parsing.
library; // Savings goal domain entity.

class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.name,
    required this.savedAmount,
    required this.status,
    required this.entryCount,
    this.targetAmount,
    this.targetDate,
    this.icon,
    this.color,
    this.note,
    this.progress,
    this.remainingAmount,
    this.monthsLeft,
    this.suggestedMonthly,
    this.isOnTrack,
  });

  final String id;
  final String name;
  final double savedAmount;

  /// 'active' | 'completed' | 'archived'
  final String status;
  final int entryCount;

  /// null = celengan bebas tanpa target.
  final double? targetAmount;
  final DateTime? targetDate;
  final String? icon;
  final String? color;
  final String? note;

  /// 0..1, null bila tanpa target.
  final double? progress;
  final double? remainingAmount;
  final int? monthsLeft;

  /// Sisa dibagi bulan tersisa — inti nilai fitur ini bagi pengguna.
  final double? suggestedMonthly;
  final bool? isOnTrack;

  bool get hasTarget => targetAmount != null && targetAmount! > 0;
  bool get isCompleted => status == 'completed';
  bool get isArchived => status == 'archived';
  bool get canWithdraw => savedAmount > 0;

  /// Persen bulat 0..100, sudah diklem supaya tidak melewati 100 saat target
  /// terlampaui. Angka aslinya tetap tersedia lewat [progress].
  int get percent =>
      hasTarget ? ((progress ?? 0) * 100).round().clamp(0, 100) : 0;

  static double _toDouble(dynamic v) => double.parse((v ?? 0).toString());

  static double? _toDoubleOrNull(dynamic v) =>
      v == null ? null : double.parse(v.toString());

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      savedAmount: _toDouble(json['saved_amount']),
      status: json['status'] as String? ?? 'active',
      entryCount: (json['entry_count'] as num?)?.toInt() ?? 0,
      targetAmount: _toDoubleOrNull(json['target_amount']),
      targetDate: json['target_date'] != null
          ? DateTime.parse(json['target_date'] as String)
          : null,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      note: json['note'] as String?,
      progress: _toDoubleOrNull(json['progress']),
      remainingAmount: _toDoubleOrNull(json['remaining_amount']),
      monthsLeft: (json['months_left'] as num?)?.toInt(),
      suggestedMonthly: _toDoubleOrNull(json['suggested_monthly']),
      isOnTrack: json['is_on_track'] as bool?,
    );
  }
}
