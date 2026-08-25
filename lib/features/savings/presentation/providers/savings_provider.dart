/// State presentation untuk Tabungan.
///
/// Mengikuti bentuk state yang sama dengan modul lain di repo ini
/// (items + isLoading + errorMessage + copyWith dengan flag clear eksplisit),
/// bukan sealed state — konsistensi antar fitur lebih penting daripada
/// memperkenalkan pola baru untuk satu modul.
library; // Savings presentation state.

import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../data/repositories/savings_repository.dart';
import '../../domain/entities/savings_entry.dart';
import '../../domain/entities/savings_goal.dart';
import '../../domain/repositories/savings_repository_contract.dart';

class SavingsState {
  const SavingsState({
    this.items = const [],
    this.statusFilter = '',
    this.isLoading = false,
    this.errorMessage,
  });

  final List<SavingsGoal> items;

  /// '' = semua status.
  final String statusFilter;
  final bool isLoading;
  final String? errorMessage;

  double get totalSaved =>
      items.fold<double>(0, (sum, goal) => sum + goal.savedAmount);

  SavingsState copyWith({
    List<SavingsGoal>? items,
    String? statusFilter,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SavingsState(
      items: items ?? this.items,
      statusFilter: statusFilter ?? this.statusFilter,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class SavingsNotifier extends StateNotifier<SavingsState> {
  SavingsNotifier(this._repo) : super(const SavingsState()) {
    load();
  }

  /// Konstruktor untuk widget test: tidak menyentuh jaringan sama sekali,
  /// sehingga halaman bisa di-pump dengan data yang ditentukan.
  @visibleForTesting
  SavingsNotifier.test({List<SavingsGoal> items = const []})
    : _repo = null,
      super(SavingsState(items: items));

  final SavingsRepositoryContract? _repo;

  Future<void> load() async {
    final repo = _repo;
    if (repo == null) return;
    // Cegah dua load berbarengan: yang selesai lebih dulu bisa menimpa hasil
    // yang lebih baru, dan daftar jadi tidak cocok dengan filter yang aktif.
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await repo.list(status: state.statusFilter);
      if (!mounted) return;
      state = state.copyWith(items: items, isLoading: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e, stack) {
      // Kegagalan parsing tidak boleh bocor ke layar sebagai
      // "type 'Null' is not a subtype of..." — itu bukan pesan untuk pengguna.
      developer.log('Gagal memuat tabungan', error: e, stackTrace: stack);
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Terjadi kesalahan. Coba lagi.',
      );
    }
  }

  Future<void> setStatusFilter(String status) async {
    if (status == state.statusFilter) return;
    state = state.copyWith(statusFilter: status);
    await load();
  }

  /// Mutasi di bawah ini sengaja TIDAK menangkap error: pemanggil (form/sheet)
  /// yang menampilkan pesannya, sama seperti modul cicilan. Yang penting
  /// daftar selalu dimuat ulang setelah sukses.
  Future<void> create({
    required String name,
    double? targetAmount,
    String? targetDate,
    String? note,
  }) async {
    await _repo!.create(
      name: name,
      targetAmount: targetAmount,
      targetDate: targetDate,
      note: note,
    );
    await load();
  }

  Future<void> update({
    required String id,
    required String name,
    double? targetAmount,
    String? targetDate,
    String? note,
    String? status,
  }) async {
    await _repo!.update(
      id: id,
      name: name,
      targetAmount: targetAmount,
      targetDate: targetDate,
      note: note,
      status: status,
    );
    await load();
  }

  Future<void> deposit({
    required String id,
    required double amount,
    String? date,
    String? note,
  }) async {
    await _repo!.deposit(id: id, amount: amount, date: date, note: note);
    await load();
  }

  Future<void> withdraw({
    required String id,
    required double amount,
    String? date,
    String? note,
  }) async {
    await _repo!.withdraw(id: id, amount: amount, date: date, note: note);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo!.delete(id);
    await load();
  }

  Future<void> deleteEntry({
    required String id,
    required String entryId,
  }) async {
    await _repo!.deleteEntry(id: id, entryId: entryId);
    await load();
  }
}

final savingsProvider =
    StateNotifierProvider<SavingsNotifier, SavingsState>((ref) {
      return SavingsNotifier(ref.watch(savingsRepositoryProvider));
    });

/// Riwayat mutasi satu pot. Dibuat family supaya tiap pot punya cache sendiri
/// dan membuka pot lain tidak menampilkan sisa data pot sebelumnya.
final savingsDetailProvider =
    FutureProvider.family<
      ({SavingsGoal goal, List<SavingsEntry> entries}),
      String
    >((ref, id) => ref.watch(savingsRepositoryProvider).detail(id));
