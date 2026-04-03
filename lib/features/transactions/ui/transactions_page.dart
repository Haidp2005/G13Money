import 'package:flutter/material.dart';

import '../data/transactions_repository.dart';
import '../../shared/widgets/category_helper.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final transactions = TransactionsRepository.instance.transactions;

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
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
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
                  color: scheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // ── Transaction Groups ──
          ...periodData.transactionGroups.map((group) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateHeader(group, scheme),
                const SizedBox(height: 12),
                _sectionCard(
                  scheme: scheme,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: group.transactions.asMap().entries.map((entry) {
                      final isLast = entry.key == group.transactions.length - 1;
                      return Column(
                        children: [
                          _buildTransactionTile(entry.value, scheme),
                          if (!isLast)
                            Divider(
                              color:
                                  scheme.outlineVariant.withValues(alpha: 0.3),
                              indent: 70,
                              height: 1,
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDateHeader(_TransactionGroup group, ColorScheme scheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          group.dayNumber,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 32,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.dayName,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              group.monthYear,
              style: TextStyle(
                color: scheme.outline,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          _formatNumber(group.total),
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTile(_TransactionItem item, ColorScheme scheme) {
    final amountColor =
        item.isIncome ? const Color(0xFF2DCC5A) : const Color(0xFFFF6B6B);

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.categoryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: item.categoryColor.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Icon(item.icon, color: item.categoryColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.note != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.note!,
                    style: TextStyle(
                      color: scheme.outline,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            _formatNumber(item.amount),
            style: TextStyle(
              color: amountColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper UI components ──
  Widget _sectionCard({
    required Widget child,
    required ColorScheme scheme,
    EdgeInsets? padding,
  }) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // ── Helper logic ──
  String _formatNumber(int number) {
    final isNegative = number < 0;
    final absNumber = number.abs();
    final str = absNumber.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return isNegative ? '-${buffer.toString()}' : buffer.toString();
  }

  _PeriodData _getPeriodData(String period) {
    if (period == 'thisWeek') {
      return _PeriodData(
        income: 500000,
        expense: 0,
        transactionGroups: [
          _TransactionGroup(
            dayNumber: '31',
            dayName: 'Thứ Ba',
            monthYear: 'tháng 3 2026',
            total: 500000,
            transactions: [
              _TransactionItem(
                title: 'Lương',
                note: 'Lương về',
                amount: 500000,
                isIncome: true,
                icon: CategoryHelper.iconFor('Lương'),
                categoryColor: CategoryHelper.colorFor('Lương'),
              ),
            ],
          ),
        ],
      );
    } else if (period == 'lastWeek') {
      return _PeriodData(
        income: 1000000,
        expense: 150000,
        transactionGroups: [
          _TransactionGroup(
            dayNumber: '25',
            dayName: 'Thứ Tư',
            monthYear: 'tháng 3 2026',
            total: 850000,
            transactions: [
              _TransactionItem(
                title: 'Tiền thưởng',
                amount: 1000000,
                isIncome: true,
                icon: CategoryHelper.iconFor('Thưởng'),
                categoryColor: CategoryHelper.colorFor('Thưởng'),
              ),
              _TransactionItem(
                title: 'Ăn uống',
                note: 'Cơm trưa',
                amount: -50000,
                isIncome: false,
                icon: CategoryHelper.iconFor('Ăn uống'),
                categoryColor: CategoryHelper.colorFor('Ăn uống'),
              ),
              _TransactionItem(
                title: 'Mua sắm',
                amount: -100000,
                isIncome: false,
                icon: CategoryHelper.iconFor('Mua sắm'),
                categoryColor: CategoryHelper.colorFor('Mua sắm'),
              ),
            ],
          ),
        ],
      );
    }
    return const _PeriodData(income: 0, expense: 0, transactionGroups: []);
  }
}

// ── Models ──
class _PeriodData {
  const _PeriodData({
    required this.income,
    required this.expense,
    required this.transactionGroups,
  });

  final int income;
  final int expense;
  final List<_TransactionGroup> transactionGroups;
}

class _TransactionGroup {
  const _TransactionGroup({
    required this.dayNumber,
    required this.dayName,
    required this.monthYear,
    required this.total,
    required this.transactions,
  });

  final String dayNumber;
  final String dayName;
  final String monthYear;
  final int total;
  final List<_TransactionItem> transactions;
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
