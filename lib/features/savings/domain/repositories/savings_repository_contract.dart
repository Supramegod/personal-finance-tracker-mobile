import '../entities/savings_entry.dart';
import '../entities/savings_goal.dart';

/// Kontrak repository tabungan. Provider diketik ke antarmuka ini supaya test
/// bisa meng-override-nya dengan fake tanpa menyentuh Dio.
abstract interface class SavingsRepositoryContract {
  /// [status] kosong berarti semua status.
  Future<List<SavingsGoal>> list({String status = ''});

  /// Detail satu pot beserta riwayat mutasinya.
  Future<({SavingsGoal goal, List<SavingsEntry> entries})> detail(String id);

  Future<SavingsGoal> create({
    required String name,
    double? targetAmount,
    String? targetDate,
    String? note,
  });

  Future<SavingsGoal> update({
    required String id,
    required String name,
    double? targetAmount,
    String? targetDate,
    String? note,
    String? status,
  });

  /// Ditolak backend (409) bila saldo pot masih ada.
  Future<void> delete(String id);

  Future<void> deposit({
    required String id,
    required double amount,
    String? date,
    String? note,
  });

  /// Ditolak backend (409) bila melebihi saldo pot.
  Future<void> withdraw({
    required String id,
    required double amount,
    String? date,
    String? note,
  });

  /// Membatalkan satu mutasi sekaligus transaksi yang tercipta bersamanya.
  Future<void> deleteEntry({required String id, required String entryId});
}
