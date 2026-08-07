/// Presentation state transaksi untuk layar Riwayat, plus
/// provider transaksi terakhir untuk Dashboard.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/transaction.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/repositories/transaction_repository_contract.dart';

@immutable
class TransactionFilter {
  const TransactionFilter({
    this.type,
    this.categoryId,
    this.from,
    this.to,
    this.search,
  });

  final TransactionType? type;
  final String? categoryId;
  final DateTime? from;
  final DateTime? to;
  final String? search;

  bool get isEmpty =>
      type == null &&
      categoryId == null &&
      from == null &&
      to == null &&
      (search == null || search!.isEmpty);

  TransactionFilter copyWith({
    TransactionType? type,
    String? categoryId,
    DateTime? from,
    DateTime? to,
    String? search,
    bool clearType = false,
    bool clearCategory = false,
    bool clearDate = false,
    bool clearSearch = false,
  }) {
    return TransactionFilter(
      type: clearType ? null : (type ?? this.type),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      from: clearDate ? null : (from ?? this.from),
      to: clearDate ? null : (to ?? this.to),
      search: clearSearch ? null : (search ?? this.search),
    );
  }
}

class TransactionListState {
  const TransactionListState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.filter = const TransactionFilter(),
    this.errorMessage,
  });

  final List<Transaction> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final TransactionFilter filter;
  final String? errorMessage;

  TransactionListState copyWith({
    List<Transaction>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    TransactionFilter? filter,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TransactionListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      filter: filter ?? this.filter,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class TransactionListNotifier extends StateNotifier<TransactionListState> {
  TransactionListNotifier(this._repo) : super(const TransactionListState()) {
    load();
  }

  final TransactionRepositoryContract _repo;
  static const _limit = 20;

  /// Muat halaman pertama (reset). Dipakai juga untuk pull-to-refresh.
  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repo.list(
        page: 1,
        limit: _limit,
        type: state.filter.type,
        categoryId: state.filter.categoryId,
        from: state.filter.from,
        to: state.filter.to,
        search: state.filter.search,
      );
      state = state.copyWith(
        items: res.data,
        page: 1,
        hasMore: res.hasMore,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final next = state.page + 1;
      final res = await _repo.list(
        page: next,
        limit: _limit,
        type: state.filter.type,
        categoryId: state.filter.categoryId,
        from: state.filter.from,
        to: state.filter.to,
        search: state.filter.search,
      );
      state = state.copyWith(
        items: [...state.items, ...res.data],
        page: next,
        hasMore: res.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, errorMessage: e.toString());
    }
  }

  Future<void> applyFilter(TransactionFilter filter) async {
    state = state.copyWith(filter: filter);
    await load();
  }

  /// Hapus transaksi (soft delete di server), buang dari list lokal lebih
  /// dulu, dan kembalikan bila permintaan gagal.
  ///
  /// Urutannya penting. Pemanggilnya adalah `onDismissed` milik Dismissible,
  /// yang berjalan SETELAH Flutter melipat barisnya. Kalau item baru dibuang
  /// setelah await berhasil, kegagalan jaringan meninggalkan item itu di
  /// dalam state; rebuild berikutnya (tarik-segarkan, loadMore, ganti filter)
  /// merender ulang Dismissible dengan ValueKey yang sama dan Flutter
  /// melempar "A dismissed Dismissible widget is still part of the tree".
  ///
  /// Menghapus lebih dulu membuat pohon widget selalu konsisten dengan apa
  /// yang sudah dilipat di layar. Error tetap dilempar ulang supaya pemanggil
  /// bisa menampilkan pesan, sementara daftarnya sendiri sudah dipulihkan.
  Future<void> delete(String id) async {
    final previousItems = state.items;
    state = state.copyWith(
      items: previousItems.where((t) => t.id != id).toList(),
    );
    try {
      await _repo.delete(id);
    } catch (_) {
      state = state.copyWith(items: previousItems);
      rethrow;
    }
  }
}

final transactionListProvider =
    StateNotifierProvider<TransactionListNotifier, TransactionListState>((ref) {
      return TransactionListNotifier(ref.watch(transactionRepositoryProvider));
    });

/// Beberapa transaksi terakhir untuk Dashboard.
final recentTransactionsProvider =
    FutureProvider.autoDispose<List<Transaction>>((ref) async {
      final res = await ref
          .watch(transactionRepositoryProvider)
          .list(page: 1, limit: 5);
      return res.data;
    });
