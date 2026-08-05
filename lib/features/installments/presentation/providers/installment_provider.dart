/// Presentation state cicilan dengan loading dan error.
///
/// [InstallmentNotifier.load] dipanggil saat konstruksi agar data
/// langsung termuat saat halaman dibuka. Method [delete] menghapus
/// item dari state lokal tanpa re-fetch.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/installment.dart';
import '../../data/repositories/installment_repository.dart';
import '../../domain/repositories/installment_repository_contract.dart';

class InstallmentState {
  const InstallmentState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Installment> items;
  final bool isLoading;
  final String? errorMessage;

  InstallmentState copyWith({
    List<Installment>? items,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return InstallmentState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class InstallmentNotifier extends StateNotifier<InstallmentState> {
  InstallmentNotifier(this._repo) : super(const InstallmentState()) {
    load();
  }

  final InstallmentRepositoryContract _repo;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repo.list();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> create({
    required String categoryId,
    required String title,
    required double monthlyAmount,
    required int tenorMonths,
    required String startDate,
    String? note,
  }) async {
    await _repo.create(
      categoryId: categoryId,
      title: title,
      monthlyAmount: monthlyAmount,
      tenorMonths: tenorMonths,
      startDate: startDate,
      note: note,
    );
    await load();
  }

  Future<void> pay(String id) async {
    await _repo.pay(id);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    state = state.copyWith(
      items: state.items.where((i) => i.id != id).toList(),
    );
  }
}

final installmentProvider =
    StateNotifierProvider<InstallmentNotifier, InstallmentState>((ref) {
      return InstallmentNotifier(ref.watch(installmentRepositoryProvider));
    });
