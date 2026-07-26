/// Model kategori transaksi.
///
/// Kategori dikelompokkan berdasarkan tipe (income/expense).
/// `is_default` = true berarti kategori bawaan sistem (tidak bisa dihapus).
library;

import 'transaction.dart';

class Category {
  final String id;
  final String name;
  final TransactionType type;
  final String? icon;
  final bool isDefault;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    this.isDefault = false,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] == 'income' ? TransactionType.income : TransactionType.expense,
      icon: json['icon'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.apiValue,
      'icon': icon,
      'is_default': isDefault,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Category && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
