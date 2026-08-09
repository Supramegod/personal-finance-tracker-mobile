/// Formatter input nominal rupiah: menyisipkan pemisah ribuan saat diketik.
///
/// Tanpa ini pengguna harus menghitung nol satu per satu untuk memastikan
/// "1500000" benar-benar satu setengah juta. Nilai yang tersimpan di controller
/// tetap teks terformat ("1.500.000"); pakai [parseIdrInput] untuk
/// mengambil angkanya sebelum dikirim ke API.
library; // IDR text input formatter.

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Ambil angka dari teks input berpemisah ribuan.
///
/// Mengembalikan 0 bila tidak ada digit sama sekali — pemanggil yang
/// membedakan "kosong" dari "nol" harus mengecek teksnya sendiri.
double parseIdrInput(String text) {
  final digits = text.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return 0;
  return double.parse(digits);
}

/// Format deretan digit jadi teks berpemisah ribuan gaya Indonesia.
String formatIdrInput(String digits) {
  final clean = digits.replaceAll(RegExp(r'\D'), '');
  if (clean.isEmpty) return '';
  return NumberFormat.decimalPattern('id_ID').format(int.parse(clean));
}

class IdrInputFormatter extends TextInputFormatter {
  const IdrInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = formatIdrInput(newValue.text);
    if (formatted.isEmpty) return TextEditingValue.empty;

    // Kursor dijangkar ke JUMLAH DIGIT sebelumnya, bukan indeks karakter —
    // indeks bergeser setiap kali pemisah ribuan muncul atau hilang, dan
    // memakainya membuat kursor melompat saat menyunting di tengah angka.
    final digitsBeforeCaret = newValue.text
        .substring(0, newValue.selection.baseOffset.clamp(0, newValue.text.length))
        .replaceAll(RegExp(r'\D'), '')
        .length;

    var seen = 0;
    var offset = formatted.length;
    for (var i = 0; i < formatted.length; i++) {
      if (seen == digitsBeforeCaret) {
        offset = i;
        break;
      }
      if (RegExp(r'\d').hasMatch(formatted[i])) seen++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
