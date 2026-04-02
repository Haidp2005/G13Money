import 'package:flutter/material.dart';

class Budget {
  final String id;
  final String title;
  final String category;
  final double limit;
  final double spent;
  final DateTime date;
  final Color color;
  final IconData icon;

  const Budget({
    required this.id,
    required this.title,
    required this.category,
    required this.limit,
    required this.spent,
    required this.date,
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
    double? limit,
    double? spent,
    DateTime? date,
    Color? color,
    IconData? icon,
  }) {
    return Budget(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      limit: limit ?? this.limit,
      spent: spent ?? this.spent,
      date: date ?? this.date,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }
}
