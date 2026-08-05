/// Presentation page untuk mencatat atau mengedit transaksi.
///
/// - Tipe: toggle income/expense
/// - Jumlah: numerik, prefix "Rp ", > 0
/// - Kategori: dari API (categoriesProvider), difilter per tipe
/// - Tanggal: date picker
/// - Catatan: opsional
///
/// Sukses simpan → invalidate list/summary/recent lalu pop.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/transaction.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/category_picker.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  /// Jika tidak null, screen dalam mode edit.
  final Transaction? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isSubmitting = false;

  TransactionType _selectedType = TransactionType.expense;
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  bool get _isEditMode => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final t = widget.transaction!;
      _selectedType = t.type;
      _amountController.text = t.amount.toStringAsFixed(0);
      _selectedDate = t.transactionDate;
      _noteController.text = t.note ?? '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Setelah kategori termuat, pilih kategori transaksi (mode edit).
  void _syncSelectedCategory(List<Category> categories) {
    if (_selectedCategory != null || !_isEditMode) return;
    final id = widget.transaction!.categoryId;
    for (final c in categories) {
      if (c.id == id) {
        _selectedCategory = c;
        break;
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pilih kategori dulu')));
      return;
    }

    setState(() => _isSubmitting = true);

    final tx = Transaction(
      id: widget.transaction?.id ?? '',
      type: _selectedType,
      amount: double.parse(_amountController.text.replaceAll('.', '').trim()),
      categoryId: _selectedCategory!.id,
      categoryName: _selectedCategory!.name,
      transactionDate: _selectedDate,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      createdAt: widget.transaction?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      final repo = ref.read(transactionRepositoryProvider);
      if (_isEditMode) {
        await repo.update(widget.transaction!.id, tx);
      } else {
        await repo.create(tx);
      }

      // Segarkan data terkait.
      ref.invalidate(recentTransactionsProvider);
      await ref.read(transactionListProvider.notifier).load();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Transaksi tersimpan')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditMode ? 'Edit Transaksi' : 'Tambah Transaksi';
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: LoadingOverlay(
        isLoading: _isSubmitting,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Tipe Transaksi
                Text(
                  'Jenis transaksi',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(
                      value: TransactionType.expense,
                      label: Text('Pengeluaran'),
                      icon: Icon(Icons.remove_circle_outline),
                    ),
                    ButtonSegment(
                      value: TransactionType.income,
                      label: Text('Pemasukan'),
                      icon: Icon(Icons.add_circle_outline),
                    ),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (selected) {
                    setState(() {
                      _selectedType = selected.first;
                      _selectedCategory = null; // Reset kategori
                    });
                  },
                ),

                const SizedBox(height: AppSpacing.xl),

                // 2. Jumlah
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  autofocus: !_isEditMode,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Jumlah (Rp)',
                    prefixText: 'Rp ',
                    prefixStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    border: OutlineInputBorder(),
                    hintText: '0',
                  ),
                  validator: Validators.validateAmount,
                ),

                const SizedBox(height: AppSpacing.lg),

                // 3. Kategori (dari API)
                categoriesAsync.when(
                  loading: () => const CategoryPicker(
                    categories: [],
                    selectedCategory: null,
                    onChanged: _noop,
                    isLoading: true,
                  ),
                  error: (e, _) => Text(
                    'Gagal memuat kategori: $e',
                    style: const TextStyle(color: AppColors.error),
                  ),
                  data: (categories) {
                    _syncSelectedCategory(categories);
                    return CategoryPicker(
                      categories: categories,
                      selectedCategory: _selectedCategory,
                      onChanged: (category) {
                        setState(() => _selectedCategory = category);
                      },
                      filterByType: _selectedType,
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                // 4. Tanggal
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      formatDate(_selectedDate),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // 5. Catatan
                TextFormField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (opsional)',
                    hintText: 'Deskripsi transaksi...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  height: AppSpacing.buttonHeight,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(
                      _isEditMode ? 'Simpan perubahan' : 'Simpan transaksi',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Callback kosong untuk CategoryPicker saat masih loading.
void _noop(Category? _) {}
