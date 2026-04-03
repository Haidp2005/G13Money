import 'package:flutter/material.dart';

import '../../accounts/data/categories_repository.dart';
import '../../accounts/models/category_item.dart';

/// Centralized category icon & color definitions.
/// All screens should use this to keep icons/colors consistent.
class CategoryHelper {
  CategoryHelper._();

  static const Map<String, IconData> _iconByKey = <String, IconData>{
    'category': Icons.category_outlined,
    'restaurant': Icons.restaurant_outlined,
    'directions_car': Icons.directions_car_outlined,
    'shopping_bag': Icons.shopping_bag_outlined,
    'home': Icons.home_outlined,
    'health': Icons.favorite_outline,
    'education': Icons.school_outlined,
    'bill': Icons.receipt_long_outlined,
    'payments': Icons.payments_outlined,
    'card_giftcard': Icons.card_giftcard_outlined,
    'trending_up': Icons.trending_up_outlined,
    'moving': Icons.moving_outlined,
    // Legacy keys
    'car': Icons.directions_car_outlined,
    'shopping': Icons.shopping_bag_outlined,
    'salary': Icons.payments_outlined,
    'bonus': Icons.card_giftcard_outlined,
    'income_other': Icons.moving_outlined,
  };

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
    final byRepo = _lookupFromRepository(category);
    if (byRepo != null) {
      return iconForKey(byRepo.iconKey);
    }
    return _lookup(category)?.icon ?? Icons.category_outlined;
  }

  /// Look up the color for a category name (case-insensitive, partial match).
  static Color colorFor(String category) {
    final byRepo = _lookupFromRepository(category);
    if (byRepo != null) {
      return _parseColor(byRepo.colorHex, fallback: const Color(0xFF0D7377));
    }
    return _lookup(category)?.color ?? const Color(0xFF0D7377);
  }

  static IconData iconForKey(String iconKey) {
    return _iconByKey[iconKey.trim()] ?? Icons.category_outlined;
  }

  static CategoryItem? _lookupFromRepository(String category) {
    final normalized = category.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    for (final item in CategoriesRepository.instance.categories) {
      if (item.name.trim().toLowerCase() == normalized) {
        return item;
      }
    }
    return null;
  }

  static Color _parseColor(String hex, {required Color fallback}) {
    final normalized = hex.trim();
    if (!normalized.startsWith('#')) return fallback;
    final raw = normalized.substring(1);
    if (raw.length != 6 && raw.length != 8) return fallback;
    final argb = raw.length == 6 ? 'FF$raw' : raw;
    final value = int.tryParse(argb, radix: 16);
    if (value == null) return fallback;
    return Color(value);
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
