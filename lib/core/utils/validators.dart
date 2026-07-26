/// Fungsi validasi form — reusable di semua screen.
///
/// Mengembalikan String? — null berarti valid, String berarti error message.
library;

abstract final class Validators {
  /// Validasi email/username tidak boleh kosong.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email atau username tidak boleh kosong';
    }
    return null;
  }

  /// Validasi password tidak boleh kosong dan minimal 6 karakter.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  /// Validasi jumlah transaksi — harus numerik dan > 0.
  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Jumlah tidak boleh kosong';
    }
    final amount = double.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    if (amount == null || amount <= 0) {
      return 'Jumlah harus lebih dari 0';
    }
    if (amount > 9999999999999.99) {
      return 'Jumlah terlalu besar';
    }
    return null;
  }

  /// Validasi kategori harus dipilih.
  static String? validateCategory(dynamic value) {
    if (value == null) {
      return 'Pilih kategori';
    }
    return null;
  }

  /// Validasi tanggal tidak boleh null.
  static String? validateDate(DateTime? value) {
    if (value == null) {
      return 'Pilih tanggal';
    }
    return null;
  }
}
