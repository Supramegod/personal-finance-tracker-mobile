/// Widget pemilih kategori — dropdown dengan ikon kategori.
///
/// Secara otomatis memfilter kategori berdasarkan tipe transaksi
/// yang dipilih (income/expense).
library; // Transaction category picker.

import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/transaction.dart';
import 'category_visual.dart';

class CategoryPicker extends StatelessWidget {
  final List<Category> categories;
  final Category? selectedCategory;
  final ValueChanged<Category?> onChanged;
  final TransactionType? filterByType;
  final bool isLoading;

  const CategoryPicker({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onChanged,
    this.filterByType,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // Filter kategori berdasarkan tipe
    final filteredCategories = filterByType != null
        ? categories.where((c) => c.type == filterByType).toList()
        : categories;

    return DropdownButtonFormField<Category>(
      initialValue: selectedCategory,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Kategori',
        hintText: 'Pilih kategori transaksi',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 54),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 10, right: 8),
          child: CategoryIconBadge(
            iconName: selectedCategory?.icon,
            type: selectedCategory?.type,
            size: 34,
            iconSize: 18,
          ),
        ),
      ),
      items: filteredCategories.map((category) {
        return DropdownMenuItem<Category>(
          value: category,
          child: Row(
            children: [
              CategoryIconBadge(
                iconName: category.icon,
                type: category.type,
                size: 34,
                iconSize: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(category.name),
            ],
          ),
        );
      }).toList(),
      selectedItemBuilder: (context) => filteredCategories
          .map(
            (category) => Align(
              alignment: Alignment.centerLeft,
              child: Text(category.name),
            ),
          )
          .toList(),
      onChanged: isLoading ? null : onChanged,
      validator: (value) {
        if (value == null) return 'Pilih kategori';
        return null;
      },
    );
  }
}
