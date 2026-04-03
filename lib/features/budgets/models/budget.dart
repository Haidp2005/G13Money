import 'package:flutter/material.dart';

class Budget {
  final String id;
  final String title;
  final String category;
  final String walletName;
  final double limit;
  final double spent;
  final DateTime startDate;
  final DateTime endDate;
  final Color color;
  final IconData icon;

  const Budget({
    required this.id,
    required this.title,
    required this.category,
    required this.walletName,
    required this.limit,
    required this.spent,
    required this.startDate,
    required this.endDate,
    required this.color,
    required this.icon,
  });

  double get remaining => limit - spent;

  double get usageRatio {
    if (limit <= 0) return 0;
    return (spent / limit).clamp(0.0, 1.0);
  }

  bool get isOverBudget => spent > limit;

  String get usageLabel => '${(usageRatio * 100).round()}%';

  Budget copyWith({
    String? id,
    String? title,
    String? category,
    String? walletName,
    double? limit,
    double? spent,
    DateTime? startDate,
    DateTime? endDate,
    Color? color,
    IconData? icon,
  }) {
    return Budget(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      walletName: walletName ?? this.walletName,
      limit: limit ?? this.limit,
      spent: spent ?? this.spent,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }
}
