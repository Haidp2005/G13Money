import 'package:flutter/material.dart';

import '../../shared/widgets/category_helper.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(title: const Text('Giao dịch'), centerTitle: true),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        itemCount: _mockTransactions.length,
        separatorBuilder: (_, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _mockTransactions[index];
          final amountColor = item.isIncome
              ? const Color(0xFF1F9D55)
              : scheme.error;

          return Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: item.color.withValues(alpha: 0.15),
                child: Icon(item.icon, color: item.color),
              ),
              title: Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(item.date),
              trailing: Text(
                item.amount,
                style: TextStyle(
                  color: amountColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TransactionItem {
  const _TransactionItem({
    required this.title,
    required this.date,
    required this.amount,
    required this.isIncome,
    required this.icon,
    required this.color,
  });

  final String title;
  final String date;
  final String amount;
  final bool isIncome;
  final IconData icon;
  final Color color;
}

final List<_TransactionItem> _mockTransactions = [
  _TransactionItem(
    title: 'Lương tháng 4',
    date: '01/04/2026',
    amount: '+12,000,000 đ',
    isIncome: true,
    icon: CategoryHelper.iconFor('Lương'),
    color: CategoryHelper.colorFor('Lương'),
  ),
  _TransactionItem(
    title: 'Ăn uống',
    date: '02/04/2026',
    amount: '-120,000 đ',
    isIncome: false,
    icon: CategoryHelper.iconFor('Ăn uống'),
    color: CategoryHelper.colorFor('Ăn uống'),
  ),
  _TransactionItem(
    title: 'Di chuyển',
    date: '02/04/2026',
    amount: '-60,000 đ',
    isIncome: false,
    icon: CategoryHelper.iconFor('Di chuyển'),
    color: CategoryHelper.colorFor('Di chuyển'),
  ),
];
