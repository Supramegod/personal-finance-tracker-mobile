/// Form bottom sheet untuk menambah cicilan baru.
///
/// Input:
/// - Nama cicilan (wajib)
/// - Kategori (expense only, dari API)
/// - Jumlah per bulan (wajib, > 0)
/// - Tenor dalam bulan (wajib, > 0)
/// - Tanggal mulai (date picker)
/// - Catatan (opsional)
///
/// Menampilkan total otomatis (jumlah × tenor) sebelum submit.
library; // Installment form widget.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/idr_input_formatter.dart';
import '../../../transactions/domain/entities/category.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/transactions_di.dart';
import '../providers/installment_provider.dart';

class InstallmentForm extends ConsumerStatefulWidget {
  const InstallmentForm({super.key});

  @override
  ConsumerState<InstallmentForm> createState() => _InstallmentFormState();
}

class _InstallmentFormState extends ConsumerState<InstallmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _tenorController = TextEditingController();
  final _noteController = TextEditingController();
  Category? _selectedCategory;
  DateTime _startDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _tenorController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pilih kategori')));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(installmentProvider.notifier)
          .create(
            categoryId: _selectedCategory!.id,
            title: _titleController.text.trim(),
            monthlyAmount: parseIdrInput(_amountController.text),
            tenorMonths: int.parse(_tenorController.text),
            startDate:
                '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
            note: _noteController.text.isNotEmpty
                ? _noteController.text.trim()
                : null,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cicilan berhasil dibuat')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
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
    final categoriesAsync = ref.watch(_installmentCategoriesProvider);
    final categories = categoriesAsync.valueOrNull ?? [];
    final expenseCategories = categories
        .where((c) => c.type == TransactionType.expense)
        .toList();

    final monthlyAmount = parseIdrInput(_amountController.text);
    final tenor = int.tryParse(_tenorController.text) ?? 0;
    final total = monthlyAmount * tenor;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Tambah Cicilan',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Nama Cicilan',
                  hintText: 'Contoh: Motor Beat',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              categoriesAsync.when(
                loading: () => const SizedBox(
                  height: 56,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (e, _) => Text(
                  'Gagal memuat kategori: $e',
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
                data: (_) => _InstallmentCategoryPicker(
                  categories: expenseCategories,
                  selectedCategory: _selectedCategory,
                  onChanged: (c) => setState(() => _selectedCategory = c),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Jumlah per Bulan',
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: const [IdrInputFormatter()],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wajib diisi';
                  if (parseIdrInput(v) <= 0) {
                    return 'Jumlah harus lebih besar dari 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _tenorController,
                decoration: const InputDecoration(
                  labelText: 'Tenor (Bulan)',
                  hintText: 'Misal: 12',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wajib diisi';
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) return 'Tenor tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    locale: const Locale('id', 'ID'),
                  );
                  if (picked != null) setState(() => _startDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Mulai',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(formatDate(_startDate)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                ),
                maxLines: 2,
              ),
              if (tenor > 0 && monthlyAmount > 0) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        formatIdr(total),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('SIMPAN'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

final _installmentCategoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(getCategoriesUseCaseProvider)(),
);

class _InstallmentCategoryPicker extends StatelessWidget {
  const _InstallmentCategoryPicker({
    required this.categories,
    required this.selectedCategory,
    required this.onChanged,
  });

  final List<Category> categories;
  final Category? selectedCategory;
  final ValueChanged<Category?> onChanged;

  @override
  Widget build(BuildContext context) {
    final expenseCategories = categories
        .where((category) => category.type == TransactionType.expense)
        .toList();
    return DropdownButtonFormField<Category>(
      initialValue: selectedCategory,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Kategori',
        hintText: 'Pilih kategori cicilan',
        prefixIconConstraints: const BoxConstraints(minWidth: 54),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 10, right: 8),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.category_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
      items: expenseCategories
          .map(
            (category) => DropdownMenuItem<Category>(
              value: category,
              child: Text(category.name),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Pilih kategori' : null,
    );
  }
}
