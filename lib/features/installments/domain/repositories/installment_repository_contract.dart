import '../entities/installment.dart';

abstract interface class InstallmentRepositoryContract {
  Future<List<Installment>> list();
  Future<Installment> create({
    required String categoryId,
    required String title,
    required double monthlyAmount,
    required int tenorMonths,
    required String startDate,
    String? note,
  });
  Future<void> pay(String id);
  Future<void> delete(String id);
}
