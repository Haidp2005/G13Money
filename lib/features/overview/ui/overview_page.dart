import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../shared/widgets/bottom_nav.dart';
import '../../shared/widgets/category_helper.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key, this.showBottomNav = true});

  final bool showBottomNav;

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  int _selectedPeriod = 1; // 0 = Tuần, 1 = Tháng

  // ── Data ──
  static const List<_WalletItem> _wallets = [
    _WalletItem(
      name: 'Chính',
      balance: '500,000 đ',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF6C63FF),
    ),
    _WalletItem(
      name: 'Tiền mặt',
      balance: '545,000 đ',
      icon: Icons.payments_rounded,
      color: Color(0xFFF09928),
    ),
  ];

  static final List<_TransactionItem> _recentTransactions = [
    _TransactionItem(
      title: 'Lương',
      date: '31 tháng 3 2026',
      amount: '+500,000',
      income: true,
      icon: CategoryHelper.iconFor('Lương'),
      categoryColor: CategoryHelper.colorFor('Lương'),
    ),
    _TransactionItem(
      title: 'Ăn uống',
      date: '29 tháng 3 2026',
      amount: '-5,000',
      income: false,
      icon: CategoryHelper.iconFor('Ăn uống'),
      categoryColor: CategoryHelper.colorFor('Ăn uống'),
    ),
    _TransactionItem(
      title: 'Thu nhập khác',
      date: '29 tháng 3 2026',
      amount: '+500,000',
      income: true,
      icon: CategoryHelper.iconFor('Thu nhập khác'),
      categoryColor: CategoryHelper.colorFor('Thu nhập khác'),
    ),
  ];

  // Monthly chart data (last 6 months)
  static const List<_ChartData> _monthlyData = [
    _ChartData(label: 'T10', income: 8.5, expense: 5.2),
    _ChartData(label: 'T11', income: 7.0, expense: 6.8),
    _ChartData(label: 'T12', income: 9.2, expense: 4.5),
    _ChartData(label: 'T1', income: 6.5, expense: 7.0),
    _ChartData(label: 'T2', income: 8.0, expense: 3.2),
    _ChartData(label: 'T3', income: 10.0, expense: 0.05),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(scheme),
              const SizedBox(height: 24),
              _buildBalanceCard(scheme),
              const SizedBox(height: 24),
              _buildReportSection(scheme),
              const SizedBox(height: 24),
              _buildWalletSection(scheme),
              const SizedBox(height: 24),
              _buildRecentTransactionsSection(scheme),
            ],
          ),
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? MoneyBottomNav(currentIndex: 0, onItemTap: (_) {}, onAddTap: () {})
          : null,
    );
  }

  // ── Header ──
  Widget _buildHeader(ColorScheme scheme) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scheme.primary, scheme.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Text(
              'G',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xin chào! 👋',
                style: TextStyle(
                  color: scheme.outline,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'G13 Money',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _headerIconButton(Icons.search_rounded, scheme),
        const SizedBox(width: 8),
        _headerIconButton(Icons.notifications_none_rounded, scheme),
      ],
    );
  }

  Widget _headerIconButton(IconData icon, ColorScheme scheme) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Icon(icon, color: scheme.onSurfaceVariant, size: 22),
    );
  }

  // ── Balance Card ──
  Widget _buildBalanceCard(ColorScheme scheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Tổng số dư',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.visibility_rounded,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '1,045,000 đ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _balanceSummaryChip(
                icon: Icons.arrow_upward_rounded,
                label: 'Thu nhập',
                value: '1,000,000',
                color: const Color(0xFF2DCC5A),
              ),
              const SizedBox(width: 12),
              _balanceSummaryChip(
                icon: Icons.arrow_downward_rounded,
                label: 'Chi tiêu',
                value: '5,000',
                color: const Color(0xFFFF6B6B),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceSummaryChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Report Section with Bar Chart ──
  Widget _buildReportSection(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: 'Báo cáo tháng này',
          action: 'Xem báo cáo',
          scheme: scheme,
        ),
        const SizedBox(height: 14),
        _sectionCard(
          scheme: scheme,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPeriodSwitch(scheme),
              const SizedBox(height: 20),
              // Summary row
              Row(
                children: [
                  _reportLegend(
                    color: scheme.primary,
                    label: 'Thu nhập',
                    scheme: scheme,
                  ),
                  const SizedBox(width: 20),
                  _reportLegend(
                    color: const Color(0xFFFF6B6B),
                    label: 'Chi tiêu',
                    scheme: scheme,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Bar chart
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 12,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipRoundedRadius: 12,
                        getTooltipColor: (_) => scheme.surfaceContainerHighest,
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final data = _monthlyData[group.x];
                          final isIncome = rodIndex == 0;
                          return BarTooltipItem(
                            '${isIncome ? "Thu" : "Chi"}: ${isIncome ? data.income : data.expense}tr',
                            TextStyle(
                              color: isIncome
                                  ? scheme.primary
                                  : const Color(0xFFFF6B6B),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < _monthlyData.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _monthlyData[index].label,
                                  style: TextStyle(
                                    color: scheme.outline,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          reservedSize: 28,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 4,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}tr',
                              style: TextStyle(
                                color: scheme.outline,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 4,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: scheme.outlineVariant.withValues(alpha: 0.3),
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        );
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: _monthlyData.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.income,
                            color: scheme.primary,
                            width: 14,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: 12,
                              color: scheme.primary.withValues(alpha: 0.08),
                            ),
                          ),
                          BarChartRodData(
                            toY: entry.value.expense,
                            color: const Color(0xFFFF6B6B),
                            width: 14,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: 12,
                              color: const Color(
                                0xFFFF6B6B,
                              ).withValues(alpha: 0.08),
                            ),
                          ),
                        ],
                        barsSpace: 4,
                      );
                    }).toList(),
                  ),
                  duration: const Duration(milliseconds: 500),
                ),
              ),
              const SizedBox(height: 16),
              // Summary totals
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Tổng thu',
                            style: TextStyle(
                              color: scheme.outline,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '1,000,000 đ',
                            style: TextStyle(
                              color: scheme.primary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 30,
                      child: VerticalDivider(
                        color: scheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Tổng chi',
                            style: TextStyle(
                              color: scheme.outline,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '5,000 đ',
                            style: TextStyle(
                              color: Color(0xFFFF6B6B),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reportLegend({
    required Color color,
    required String label,
    required ColorScheme scheme,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Wallet Section ──
  Widget _buildWalletSection(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: 'Ví của tôi',
          action: 'Xem tất cả',
          scheme: scheme,
        ),
        const SizedBox(height: 14),
        _sectionCard(
          scheme: scheme,
          child: Column(
            children: [
              ..._wallets.asMap().entries.map((entry) {
                final isLast = entry.key == _wallets.length - 1;
                return Column(
                  children: [
                    _walletTile(entry.value, scheme),
                    if (!isLast)
                      Divider(
                        color: scheme.outlineVariant.withValues(alpha: 0.3),
                        height: 1,
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // ── Recent Transactions Section ──
  Widget _buildRecentTransactionsSection(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: 'Giao dịch gần đây',
          action: 'Xem tất cả',
          scheme: scheme,
        ),
        const SizedBox(height: 14),
        _sectionCard(
          scheme: scheme,
          child: Column(
            children: _recentTransactions.asMap().entries.map((entry) {
              final isLast = entry.key == _recentTransactions.length - 1;
              return Column(
                children: [
                  _transactionTile(entry.value, scheme),
                  if (!isLast)
                    Divider(
                      color: scheme.outlineVariant.withValues(alpha: 0.3),
                      height: 1,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Wallet Tile ──
  Widget _walletTile(_WalletItem item, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: item.color.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Icon(item.icon, color: item.color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              item.name,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            item.balance,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            color: scheme.outline,
            size: 20,
          ),
        ],
      ),
    );
  }

  // ── Transaction Tile ──
  Widget _transactionTile(_TransactionItem item, ColorScheme scheme) {
    final Color amountColor = item.income
        ? const Color(0xFF2DCC5A)
        : const Color(0xFFFF6B6B);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
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
                const SizedBox(height: 3),
                Text(
                  item.date,
                  style: TextStyle(
                    color: scheme.outline,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            item.amount,
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

  // ── Period Switch ──
  Widget _buildPeriodSwitch(ColorScheme scheme) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _periodTab('Tuần', 0, scheme),
          _periodTab('Tháng', 1, scheme),
        ],
      ),
    );
  }

  Widget _periodTab(String label, int index, ColorScheme scheme) {
    final isSelected = _selectedPeriod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : scheme.outline,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ── Shared components ──
  Widget _sectionCard({required Widget child, required ColorScheme scheme}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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

  Widget _sectionHeader({
    required String title,
    required String action,
    required ColorScheme scheme,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {},
          child: Row(
            children: [
              Text(
                action,
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: scheme.primary,
                size: 12,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Data Models ──

class _WalletItem {
  const _WalletItem({
    required this.name,
    required this.balance,
    required this.icon,
    required this.color,
  });

  final String name;
  final String balance;
  final IconData icon;
  final Color color;
}

class _TransactionItem {
  const _TransactionItem({
    required this.title,
    required this.date,
    required this.amount,
    required this.income,
    required this.icon,
    required this.categoryColor,
  });

  final String title;
  final String date;
  final String amount;
  final bool income;
  final IconData icon;
  final Color categoryColor;
}

class _ChartData {
  const _ChartData({
    required this.label,
    required this.income,
    required this.expense,
  });

  final String label;
  final double income;
  final double expense;
}
