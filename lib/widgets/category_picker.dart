/// Widget pemilih kategori — dropdown dengan ikon kategori.
///
/// Secara otomatis memfilter kategori berdasarkan tipe transaksi
/// yang dipilih (income/expense).
library;

import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_spacing.dart';
import '../models/category.dart';
import '../models/transaction.dart';

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
      value: selectedCategory,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Kategori',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        ),
        prefixIcon: selectedCategory != null
            ? Icon(
                _mapIcon(selectedCategory!.icon),
                color: AppColors.primary,
              )
            : const Icon(Icons.category),
      ),
      items: filteredCategories.map((category) {
        return DropdownMenuItem<Category>(
          value: category,
          child: Row(
            children: [
              Icon(
                _mapIcon(category.icon),
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(category.name),
            ],
          ),
        );
      }).toList(),
      onChanged: isLoading ? null : onChanged,
      validator: (value) {
        if (value == null) return 'Pilih kategori';
        return null;
      },
    );
  }

  static IconData _mapIcon(String? iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'work':
        return Icons.work;
      case 'directions_car':
        return Icons.directions_car;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'health_and_safety':
        return Icons.health_and_safety;
      case 'school':
        return Icons.school;
      case 'home':
        return Icons.home;
      case 'flight':
        return Icons.flight;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'checkroom':
        return Icons.checkroom;
      default:
        return Icons.category;
    }
  }
}
