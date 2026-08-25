import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Seam override untuk fitur Tabungan. Provider Riverpod bersifat lazy, jadi
/// daftar ini kosong secara default — keberadaannya menjaga agar test dan
/// lingkungan alternatif punya satu tempat untuk menyuntik dependensi.
List<Override> registerSavingsDependencies() => const [];
