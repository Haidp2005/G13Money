import 'package:flutter/material.dart';

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

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──
            _buildTopBar(scheme),
            // ── Balance ──
            _buildBalanceSection(scheme),
            // ── Tab Bar ──
            _buildTabBar(scheme),
            // ── Content ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildTabContent(period: 'lastWeek', scheme: scheme),
                  _buildTabContent(period: 'thisWeek', scheme: scheme),
                  _buildTabContent(period: 'future', scheme: scheme),
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
  Widget _buildBalanceSection(ColorScheme scheme) {
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
            '1,045,000 đ',
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
  Widget _buildTabContent({required String period, required ColorScheme scheme}) {
    final periodData = _getPeriodData(period);

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
                _summaryRow('Tiền vào', _formatNumber(periodData.income),
                    const Color(0xFF2DCC5A)),
                const SizedBox(height: 12),
                _summaryRow('Tiền ra', _formatNumber(periodData.expense),
                    const Color(0xFFFF6B6B)),
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
    this.note,
    required this.amount,
    required this.isIncome,
    required this.icon,
    required this.categoryColor,
  });

  final String title;
  final String? note;
  final int amount;
  final bool isIncome;
  final IconData icon;
  final Color categoryColor;
}
