import 'package:flutter/material.dart';

import '../../domain/entities/transaction.dart';

/// Satu sumber visual untuk ikon kategori dari backend.
abstract final class CategoryVisual {
  static IconData icon(String? name, {TransactionType? type}) {
    switch (name?.trim().toLowerCase()) {
      case 'salary':
        return Icons.payments_rounded;
      case 'freelance':
        return Icons.laptop_mac_rounded;
      case 'business':
        return Icons.storefront_rounded;
      case 'investment':
        return Icons.trending_up_rounded;
      case 'gift':
        return Icons.redeem_rounded;
      case 'food':
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'transport':
      case 'directions_car':
        return Icons.directions_transit_rounded;
      case 'shopping':
      case 'shopping_cart':
        return Icons.shopping_bag_rounded;
      case 'entertainment':
      case 'sports_esports':
        return Icons.movie_rounded;
      case 'health':
      case 'health_and_safety':
        return Icons.health_and_safety_rounded;
      case 'education':
      case 'school':
        return Icons.school_rounded;
      case 'bill':
        return Icons.receipt_long_rounded;
      case 'savings':
        return Icons.savings_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'flight':
        return Icons.flight_rounded;
      case 'checkroom':
        return Icons.checkroom_rounded;
      case 'other_income':
        return Icons.add_chart_rounded;
      case 'other_expense':
        return Icons.more_horiz_rounded;
      default:
        return type == TransactionType.income
            ? Icons.arrow_upward_rounded
            : type == TransactionType.expense
            ? Icons.arrow_downward_rounded
            : Icons.category_rounded;
    }
  }

  static Color color(String? name, {TransactionType? type}) {
    switch (name?.trim().toLowerCase()) {
      case 'salary':
        return const Color(0xFF16A085);
      case 'freelance':
        return const Color(0xFF4F7DF3);
      case 'business':
        return const Color(0xFF8B5CF6);
      case 'investment':
        return const Color(0xFF0EA5A4);
      case 'gift':
        return const Color(0xFFEC4899);
      case 'food':
      case 'restaurant':
        return const Color(0xFFF97316);
      case 'transport':
      case 'directions_car':
        return const Color(0xFF3B82F6);
      case 'shopping':
      case 'shopping_cart':
        return const Color(0xFFD946EF);
      case 'entertainment':
      case 'sports_esports':
        return const Color(0xFF8B5CF6);
      case 'health':
      case 'health_and_safety':
        return const Color(0xFFEF476F);
      case 'education':
      case 'school':
        return const Color(0xFF6366F1);
      case 'bill':
        return const Color(0xFFF59E0B);
      case 'savings':
        return const Color(0xFF14B8A6);
      default:
        return type == null
            ? const Color(0xFF718096)
            : type == TransactionType.income
            ? const Color(0xFF20B486)
            : const Color(0xFFFF6B6B);
    }
  }
}

class CategoryIconBadge extends StatelessWidget {
  const CategoryIconBadge({
    super.key,
    required this.iconName,
    this.type,
    this.size = 40,
    this.iconSize = 20,
  });

  final String? iconName;
  final TransactionType? type;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final color = CategoryVisual.color(iconName, type: type);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * .32),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      alignment: Alignment.center,
      child: Icon(
        CategoryVisual.icon(iconName, type: type),
        color: color,
        size: iconSize,
      ),
    );
  }
}
