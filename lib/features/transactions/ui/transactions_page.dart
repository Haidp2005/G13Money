import 'package:flutter/material.dart';

import '../data/transactions_repository.dart';
import '../models/transaction.dart';
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
    final balance = transactions.fold<int>(
      0,
      (sum, tx) => sum + (tx.isIncome ? tx.amount.round() : -tx.amount.round()),
    );

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──
            _buildTopBar(scheme),
            // ── Balance ──
            _buildBalanceSection(scheme, balance),
            // ── Tab Bar ──
            _buildTabBar(scheme),
            // ── Content ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildTabContent(
                    period: 'lastWeek',
                    scheme: scheme,
                    transactions: transactions,
                  ),
                  _buildTabContent(
                    period: 'thisWeek',
                    scheme: scheme,
                    transactions: transactions,
                  ),
                  _buildTabContent(
                    period: 'future',
                    scheme: scheme,
                    transactions: transactions,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ──
  Widget _buildTopBar(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _headerIconButton(Icons.help_outline_rounded, scheme),
          const Spacer(),
          // Wallet selector chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🌐', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  'Tổng cộng',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: scheme.outline,
                  size: 18,
                ),
              ],
            ),
          ),
          const Spacer(),
          _headerIconButton(Icons.search_rounded, scheme),
          const SizedBox(width: 8),
          _headerIconButton(Icons.more_vert_rounded, scheme),
        ],
      ),
    );
  }

  Widget _headerIconButton(IconData icon, ColorScheme scheme) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(icon, color: scheme.onSurfaceVariant, size: 22),
    );
  }

  // ── Balance Section ──
  Widget _buildBalanceSection(ColorScheme scheme, int balance) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      child: Column(
        children: [
          Text(
            'Số dư',
            style: TextStyle(
              color: scheme.outline,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatNumber(balance)} đ',
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Bar ──
  Widget _buildTabBar(ColorScheme scheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.outline,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        indicatorColor: scheme.primary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(vertical: 4),
        tabs: const [
          Tab(text: 'TUẦN TRƯỚC'),
          Tab(text: 'TUẦN NÀY'),
          Tab(text: 'TƯƠNG LAI'),
        ],
      ),
    );
  }

  // ── Tab Content ──
  Widget _buildTabContent({
    required String period,
    required ColorScheme scheme,
    required List<MoneyTransaction> transactions,
  }) {
    final periodData = _getPeriodData(period, transactions);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        children: [
          // ── Summary Card ──
          _sectionCard(
            scheme: scheme,
            child: Column(
              children: [
                _summaryRow(
                  'Tiền vào',
                  _formatNumber(periodData.income),
                  const Color(0xFF2DCC5A),
                ),
                const SizedBox(height: 12),
                _summaryRow(
                  'Tiền ra',
                  _formatNumber(periodData.expense),
                  const Color(0xFFFF6B6B),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(
                    color: scheme.outlineVariant.withValues(alpha: 0.4),
                    height: 1,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _formatNumber(periodData.income - periodData.expense),
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── Report Button ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: scheme.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: scheme.primary.withValues(alpha: 0.04),
              ),
              child: Text(
                'Xem báo cáo cho giai đoạn này',
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
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.3,
                              ),
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
              style: TextStyle(color: scheme.outline, fontSize: 12),
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
    final amountColor = item.isIncome
        ? const Color(0xFF2DCC5A)
        : const Color(0xFFFF6B6B);

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

  _PeriodData _getPeriodData(
    String period,
    List<MoneyTransaction> transactions,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfThisWeek = _startOfWeek(today);
    final endOfThisWeek = startOfThisWeek.add(const Duration(days: 6));
    final startOfLastWeek = startOfThisWeek.subtract(const Duration(days: 7));
    final endOfLastWeek = startOfThisWeek.subtract(const Duration(days: 1));

    bool inPeriod(MoneyTransaction tx) {
      final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
      if (period == 'thisWeek') {
        return !date.isBefore(startOfThisWeek) && !date.isAfter(endOfThisWeek);
      }
      if (period == 'lastWeek') {
        return !date.isBefore(startOfLastWeek) && !date.isAfter(endOfLastWeek);
      }
      return date.isAfter(endOfThisWeek);
    }

    final periodTransactions = transactions.where(inPeriod).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final income = periodTransactions
        .where((tx) => tx.isIncome)
        .fold<int>(0, (sum, tx) => sum + tx.amount.round());
    final expense = periodTransactions
        .where((tx) => !tx.isIncome)
        .fold<int>(0, (sum, tx) => sum + tx.amount.round());

    final grouped = <DateTime, List<MoneyTransaction>>{};
    for (final tx in periodTransactions) {
      final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
      grouped.putIfAbsent(day, () => <MoneyTransaction>[]).add(tx);
    }

    final sortedDays = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final groups = sortedDays.map((day) {
      final entries = grouped[day]!;
      final total = entries.fold<int>(
        0,
        (sum, tx) =>
            sum + (tx.isIncome ? tx.amount.round() : -tx.amount.round()),
      );
      final items = entries
          .map(
            (tx) => _TransactionItem(
              title: tx.title,
              amount: tx.isIncome ? tx.amount.round() : -tx.amount.round(),
              isIncome: tx.isIncome,
              icon: CategoryHelper.iconFor(tx.category),
              categoryColor: CategoryHelper.colorFor(tx.category),
            ),
          )
          .toList();

      return _TransactionGroup(
        dayNumber: day.day.toString().padLeft(2, '0'),
        dayName: _weekdayLabel(day.weekday),
        monthYear: 'tháng ${day.month} ${day.year}',
        total: total,
        transactions: items,
      );
    }).toList();

    return _PeriodData(
      income: income,
      expense: expense,
      transactionGroups: groups,
    );
  }

  DateTime _startOfWeek(DateTime date) {
    final difference = date.weekday - DateTime.monday;
    return date.subtract(Duration(days: difference));
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Thứ Hai';
      case DateTime.tuesday:
        return 'Thứ Ba';
      case DateTime.wednesday:
        return 'Thứ Tư';
      case DateTime.thursday:
        return 'Thứ Năm';
      case DateTime.friday:
        return 'Thứ Sáu';
      case DateTime.saturday:
        return 'Thứ Bảy';
      default:
        return 'Chủ nhật';
    }
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
    required this.amount,
    required this.isIncome,
    required this.icon,
    required this.categoryColor,
  });

  final String title;
  final int amount;
  final bool isIncome;
  final IconData icon;
  final Color categoryColor;
}
