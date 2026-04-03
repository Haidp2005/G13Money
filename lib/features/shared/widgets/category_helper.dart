import 'package:flutter/material.dart';

/// Centralized category icon & color definitions.
/// All screens should use this to keep icons/colors consistent.
class CategoryHelper {
  CategoryHelper._();

  // ── Income categories ──
  static const _incomeCategories = <String, _CategoryStyle>{
    'lương': _CategoryStyle(Icons.payments_outlined, Color(0xFF2DCC5A)),
    'thu nhập khác': _CategoryStyle(Icons.moving_outlined, Color(0xFF0D7377)),
    'thưởng': _CategoryStyle(Icons.card_giftcard_outlined, Color(0xFFF09928)),
  };

  // ── Expense categories ──
  static const _expenseCategories = <String, _CategoryStyle>{
    'ăn uống': _CategoryStyle(Icons.restaurant_outlined, Color(0xFFE07A5F)),
    'di chuyển': _CategoryStyle(Icons.directions_car_outlined, Color(0xFF3D5A80)),
    'mua sắm': _CategoryStyle(Icons.shopping_bag_outlined, Color(0xFF9B5DE5)),
    'nhà ở': _CategoryStyle(Icons.home_outlined, Color(0xFF81B29A)),
    'giải trí': _CategoryStyle(Icons.sports_esports_outlined, Color(0xFFFF6B6B)),
    'sức khỏe': _CategoryStyle(Icons.favorite_outline, Color(0xFFEF476F)),
    'giáo dục': _CategoryStyle(Icons.school_outlined, Color(0xFF118AB2)),
    'hóa đơn': _CategoryStyle(Icons.receipt_long_outlined, Color(0xFF073B4C)),
  };

  /// Look up the icon for a category name (case-insensitive, partial match).
  static IconData iconFor(String category) {
    return _lookup(category)?.icon ?? Icons.account_balance_wallet_outlined;
  }

  /// Look up the color for a category name (case-insensitive, partial match).
  static Color colorFor(String category) {
    return _lookup(category)?.color ?? const Color(0xFF0D7377);
  }

  static _CategoryStyle? _lookup(String category) {
    final key = category.toLowerCase().trim();

    // Exact match first
    if (_incomeCategories.containsKey(key)) return _incomeCategories[key];
    if (_expenseCategories.containsKey(key)) return _expenseCategories[key];

    // Partial match
    for (final entry in _incomeCategories.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return entry.value;
      }
    }
    for (final entry in _expenseCategories.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return entry.value;
      }
    }

    return null;
  }
}

class _CategoryStyle {
  const _CategoryStyle(this.icon, this.color);

  final IconData icon;
  final Color color;
}
