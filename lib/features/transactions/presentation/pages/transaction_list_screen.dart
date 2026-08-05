/// Presentation page riwayat transaksi dengan filter dan paginasi.
///
/// - Infinite scroll (20/hal) via transactionListProvider.loadMore()
/// - Filter tipe (income/expense), kategori, dan rentang tanggal
/// - Pull-to-refresh, swipe-to-delete (soft delete di server)
/// - Grouping per tanggal (Hari Ini, Kemarin, dll)
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/transaction.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_tile.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _searchText = value);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      final currentFilter = ref.read(transactionListProvider).filter;
      ref
          .read(transactionListProvider.notifier)
          .applyFilter(
            currentFilter.copyWith(
              search: value.isEmpty ? null : value,
              clearSearch: value.isEmpty,
            ),
          );
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(transactionListProvider.notifier).loadMore();
    }
  }

  Future<void> _handleDelete(Transaction tx) async {
    try {
      await ref.read(transactionListProvider.notifier).delete(tx.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${tx.categoryName} dihapus')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Map<String, List<Transaction>> _groupByDate(List<Transaction> transactions) {
    final grouped = <String, List<Transaction>>{};
    for (final tx in transactions) {
      final key = formatDateRelative(tx.transactionDate);
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(tx);
    }
    return grouped;
  }

  Future<void> _pickDateRange(TransactionFilter filter) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: filter.from != null && filter.to != null
          ? DateTimeRange(start: filter.from!, end: filter.to!)
          : null,
      locale: const Locale('id', 'ID'),
    );
    if (range != null) {
      ref
          .read(transactionListProvider.notifier)
          .applyFilter(filter.copyWith(from: range.start, to: range.end));
    }
  }

  Future<void> _pickCategory(TransactionFilter filter) async {
    final categories = await ref.read(categoriesProvider.future);
    if (!mounted) return;
    final picked = await showModalBottomSheet<Category>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: categories
            .map(
              (c) => ListTile(
                title: Text(c.name),
                trailing: filter.categoryId == c.id
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, c),
              ),
            )
            .toList(),
      ),
    );
    if (picked != null) {
      ref
          .read(transactionListProvider.notifier)
          .applyFilter(filter.copyWith(categoryId: picked.id));
    }
  }

  Future<void> _showFilters(TransactionFilter filter) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Filter transaksi',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.md),
              SegmentedButton<TransactionType?>(
                segments: const [
                  ButtonSegment(value: null, label: Text('Semua')),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Masuk'),
                  ),
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Keluar'),
                  ),
                ],
                selected: {filter.type},
                onSelectionChanged: (value) {
                  final type = value.first;
                  ref
                      .read(transactionListProvider.notifier)
                      .applyFilter(
                        filter.copyWith(type: type, clearType: type == null),
                      );
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: const Icon(Icons.date_range_outlined),
                title: const Text('Rentang tanggal'),
                trailing: filter.from != null
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(context, 'date'),
              ),
              ListTile(
                leading: const Icon(Icons.category_outlined),
                title: const Text('Kategori'),
                trailing: filter.categoryId != null
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(context, 'category'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: () {
                  _clearSearch();
                  ref
                      .read(transactionListProvider.notifier)
                      .applyFilter(const TransactionFilter());
                  Navigator.pop(context);
                },
                child: const Text('Reset filter'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'date') await _pickDateRange(filter);
    if (action == 'category') await _pickCategory(filter);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionListProvider);
    final filter = state.filter;
    final grouped = _groupByDate(state.items);

    return Scaffold(
      appBar: AppBar(title: const Text('Transaksi')),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              AppSpacing.sm,
              AppSpacing.screenHorizontal,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari transaksi...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchText.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: _clearSearch,
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.buttonRadius,
                        ),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.buttonRadius,
                        ),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.buttonRadius,
                        ),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton.filledTonal(
                  tooltip: 'Filter',
                  onPressed: () => _showFilters(filter),
                  icon: Badge(
                    isLabelVisible: !filter.isEmpty,
                    child: const Icon(Icons.tune_rounded),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          const Divider(height: 1),

          Expanded(child: _buildBody(context, state, grouped)),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    TransactionListState state,
    Map<String, List<Transaction>> grouped,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.cloud_off,
        title: 'Gagal memuat',
        subtitle: state.errorMessage!,
        actionLabel: 'Coba Lagi',
        onAction: () => ref.read(transactionListProvider.notifier).load(),
      );
    }

    if (state.items.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.receipt_long_outlined,
        title: 'Belum ada transaksi',
        subtitle:
            'Mulai catat pengeluaran atau pemasukan pertama dengan tekan tombol +',
        actionLabel: 'Tambah Transaksi',
        onAction: () => context.push('/add-transaction'),
      );
    }

    final entries = grouped.entries.toList();
    return RefreshIndicator(
      onRefresh: () => ref.read(transactionListProvider.notifier).load(),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: entries.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= entries.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final entry = entries[index];
          return _TransactionGroup(
            dateLabel: entry.key,
            transactions: entry.value,
            onTapTransaction: (tx) =>
                context.push('/add-transaction', extra: tx),
            onDeleteTransaction: _handleDelete,
          );
        },
      ),
    );
  }
}

class _TransactionGroup extends StatelessWidget {
  final String dateLabel;
  final List<Transaction> transactions;
  final void Function(Transaction) onTapTransaction;
  final void Function(Transaction) onDeleteTransaction;

  const _TransactionGroup({
    required this.dateLabel,
    required this.transactions,
    required this.onTapTransaction,
    required this.onDeleteTransaction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.md,
            AppSpacing.screenHorizontal,
            AppSpacing.xs,
          ),
          child: Text(dateLabel, style: AppTextStyles.sectionHeader(context)),
        ),
        ...transactions.map(
          (tx) => TransactionTile(
            transaction: tx,
            onTap: () => onTapTransaction(tx),
            onDelete: () => onDeleteTransaction(tx),
          ),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}
