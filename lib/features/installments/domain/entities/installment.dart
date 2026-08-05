/// Model cicilan (installment) — rencana pembayaran bertahap.
///
/// Setiap cicilan memiliki jumlah per bulan, tenor, dan progres pembayaran.
/// `paid` = true menandakan semua bulan sudah lunas.
library; // Installment domain entity.

class Installment {
  final String id;
  final String title;
  final String categoryId;
  final String categoryName;
  final double monthlyAmount;
  final int tenorMonths;
  final int paidCount;
  final DateTime startDate;
  final String? note;
  final bool paid;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Installment({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.categoryName,
    required this.monthlyAmount,
    required this.tenorMonths,
    required this.paidCount,
    required this.startDate,
    this.note,
    required this.paid,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalAmount => monthlyAmount * tenorMonths;

  double get remainingAmount => monthlyAmount * (tenorMonths - paidCount);

  double get progress => tenorMonths > 0 ? paidCount / tenorMonths : 0;

  DateTime get nextDueDate =>
      DateTime(startDate.year, startDate.month + paidCount, startDate.day);

  DateTime? get completionDate => paid
      ? DateTime(startDate.year, startDate.month + paidCount, startDate.day)
      : null;

  DateTime get estimatedCompletionDate =>
      DateTime(startDate.year, startDate.month + tenorMonths, startDate.day);

  factory Installment.fromJson(Map<String, dynamic> json) {
    return Installment(
      id: json['id'] as String,
      title: json['title'] as String,
      categoryId: json['category_id'] as String? ?? '',
      categoryName: json['category_name'] as String? ?? '',
      monthlyAmount: double.parse((json['monthly_amount'] ?? 0).toString()),
      tenorMonths: (json['tenor_months'] as num?)?.toInt() ?? 0,
      paidCount: (json['paid_count'] as num?)?.toInt() ?? 0,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : DateTime.now(),
      note: json['note'] as String?,
      paid: json['paid'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }
}
