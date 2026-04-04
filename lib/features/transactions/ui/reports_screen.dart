import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/category_helper.dart';
import '../../accounts/data/accounts_repository.dart';
import '../../accounts/data/categories_repository.dart';
import '../models/transaction.dart';
import '../data/transactions_repository.dart';
import '../state/reports_state.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    await Future.wait([
      TransactionsRepository.instance.loadTransactions(forceRefresh: true),
      AccountsRepository.instance.loadAccounts(forceRefresh: true),
      CategoriesRepository.instance.loadCategories(forceRefresh: true),
    ]);
    ref.read(reportsReloadTickProvider.notifier).state++;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(reportsReloadTickProvider);
    final touchedExpenseIndex = ref.watch(reportsTouchedExpenseIndexProvider);
    final touchedIncomeIndex = ref.watch(reportsTouchedIncomeIndexProvider);
    final scheme = Theme.of(context).colorScheme;

    final now = DateTime.now();
    final transactions = TransactionsRepository.instance.transactions
        .where((t) => _isInCurrentMonth(t.date, now))
        .toList(growable: false);
    final incomeTx = transactions.where((t) => t.isIncome).toList(growable: false);
    final expenseTx = transactions.where((t) => !t.isIncome).toList(growable: false);

    final totalIncome = incomeTx.fold<double>(0, (s, t) => s + t.amount);
    final totalExpense = expenseTx.fold<double>(0, (s, t) => s + t.amount);
    final totalBalance = AccountsRepository.instance.accounts
        .fold<double>(0, (s, a) => s + a.balance);

    // Group by category
    final expenseByCategory = _groupByCategory(expenseTx);
    final incomeByCategory = _groupByCategory(incomeTx);

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          'Báo cáo tháng ${now.month}/${now.year}',
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        shadowColor: scheme.shadow.withValues(alpha: 0.2),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Balance Card ──────────────────────────────
            _BalanceCard(
              scheme: scheme,
              totalBalance: totalBalance,
              totalIncome: totalIncome,
              totalExpense: totalExpense,
              formatCurrency: _formatCurrency,
            ),
            const SizedBox(height: 24),

            // ── Chi tiêu Chart ────────────────────────────
            _SectionTitle(scheme: scheme, label: 'Chi tiêu theo danh mục'),
            const SizedBox(height: 12),
            _DonutChartCard(
              scheme: scheme,
              title: 'Chi tiêu',
              amount: totalExpense,
              isIncome: false,
              byCategory: expenseByCategory,
              touchedIndex: touchedExpenseIndex,
              onTouched: (idx) {
                ref.read(reportsTouchedExpenseIndexProvider.notifier).state = idx;
              },
              formatCurrency: _formatCurrency,
            ),
            const SizedBox(height: 20),

            // ── Thu nhập Chart ────────────────────────────
            _SectionTitle(scheme: scheme, label: 'Thu nhập theo danh mục'),
            const SizedBox(height: 12),
            _DonutChartCard(
              scheme: scheme,
              title: 'Thu nhập',
              amount: totalIncome,
              isIncome: true,
              byCategory: incomeByCategory,
              touchedIndex: touchedIncomeIndex,
              onTouched: (idx) {
                ref.read(reportsTouchedIncomeIndexProvider.notifier).state = idx;
              },
              formatCurrency: _formatCurrency,
            ),
            const SizedBox(height: 24),

            // ── Transaction list ──────────────────────────
            _SectionTitle(scheme: scheme, label: 'Chi tiết giao dịch'),
            const SizedBox(height: 12),
            _TransactionList(scheme: scheme, transactions: transactions, formatCurrency: _formatCurrency),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Map<String, double> _groupByCategory(List<MoneyTransaction> txList) {
    final map = <String, double>{};
    for (final tx in txList) {
      map[tx.category] = (map[tx.category] ?? 0) + tx.amount;
    }
    // Sort descending by value
    final sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  String _formatCurrency(double value, {String prefix = ''}) {
    final absValue = value.abs().toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < absValue.length; i++) {
      if (i > 0 && (absValue.length - i) % 3 == 0) buffer.write(',');
      buffer.write(absValue[i]);
    }
    if (prefix.isNotEmpty) return '$prefix${buffer.toString()} ₫';
    return '${value < 0 ? "-" : ""}${buffer.toString()} ₫';
  }

  bool _isInCurrentMonth(DateTime value, DateTime now) =>
      value.year == now.year && value.month == now.month;
}

// ─────────────────────────────────────────────────────────────────────────────
// Balance Card
// ─────────────────────────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final ColorScheme scheme;
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;
  final String Function(double, {String prefix}) formatCurrency;

  const _BalanceCard({
    required this.scheme,
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF22B45E),
            const Color(0xFF1A9E52),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22B45E).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Số dư hiện tại',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatCurrency(totalBalance),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MiniSummary(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Thu nhập',
                  value: formatCurrency(totalIncome),
                  iconColor: Colors.white,
                  bgColor: Colors.white.withValues(alpha: 0.18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniSummary(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Chi tiêu',
                  value: formatCurrency(totalExpense),
                  iconColor: Colors.white,
                  bgColor: Colors.white.withValues(alpha: 0.18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniSummary extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color bgColor;

  const _MiniSummary({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Title
// ─────────────────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final ColorScheme scheme;
  final String label;

  const _SectionTitle({required this.scheme, required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Donut Chart Card (full-width with legend below)
// ─────────────────────────────────────────────────────────────────────────────
class _DonutChartCard extends StatelessWidget {
  final ColorScheme scheme;
  final String title;
  final double amount;
  final bool isIncome;
  final Map<String, double> byCategory;
  final int touchedIndex;
  final void Function(int) onTouched;
  final String Function(double, {String prefix}) formatCurrency;

  const _DonutChartCard({
    required this.scheme,
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.byCategory,
    required this.touchedIndex,
    required this.onTouched,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final categories = byCategory.keys.toList();
    final noData = categories.isEmpty;
    final accentColor = isIncome ? const Color(0xFF22B45E) : const Color(0xFFFF5252);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Total label ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng $title',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                noData ? '0 ₫' : formatCurrency(amount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (noData) ...[
            // ── Empty state ──
            SizedBox(
              height: 140,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pie_chart_outline, size: 48, color: scheme.outlineVariant),
                  const SizedBox(height: 8),
                  Text(
                    'Chưa có dữ liệu',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ),
            ),
          ] else ...[
            // ── Donut chart ──
            SizedBox(
              height: 160,
              child: Row(
                children: [
                  // Chart
                  SizedBox(
                    width: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  onTouched(-1);
                                  return;
                                }
                                onTouched(pieTouchResponse.touchedSection!.touchedSectionIndex);
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 2.5,
                            centerSpaceRadius: 44,
                            sections: categories.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final cat = entry.value;
                              final val = byCategory[cat]!;
                              final isTouched = idx == touchedIndex;
                              return PieChartSectionData(
                                color: CategoryHelper.colorFor(cat),
                                value: val,
                                title: '',
                                radius: isTouched ? 24.0 : 16.0,
                              );
                            }).toList(),
                          ),
                        ),
                        // Center text
                        if (touchedIndex >= 0 && touchedIndex < categories.length)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${((byCategory[categories[touchedIndex]]! / amount) * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: scheme.onSurface,
                                ),
                              ),
                              Text(
                                categories[touchedIndex],
                                style: TextStyle(
                                  fontSize: 10,
                                  color: scheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                        else
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${categories.length}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: scheme.onSurface,
                                ),
                              ),
                              Text(
                                'danh mục',
                                style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Right side legend (top categories, max 4)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: categories.take(4).map((cat) {
                        final pct = (byCategory[cat]! / amount * 100);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: CategoryHelper.colorFor(cat),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: scheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${pct.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // ── Category % legend below chart ──────────────
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Text(
              'Tỷ lệ chi tiêu theo danh mục',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ...categories.map((cat) {
              final val = byCategory[cat]!;
              final pct = val / amount;
              final color = CategoryHelper.colorFor(cat);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(CategoryHelper.iconFor(cat), color: color, size: 14),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          '${(pct * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatCurrency(val),
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 5,
                        backgroundColor: color.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Transaction List
// ─────────────────────────────────────────────────────────────────────────────
class _TransactionList extends StatelessWidget {
  final ColorScheme scheme;
  final List<MoneyTransaction> transactions;
  final String Function(double, {String prefix}) formatCurrency;

  const _TransactionList({
    required this.scheme,
    required this.transactions,
    required this.formatCurrency,
  });

  String _shortDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined, size: 44, color: scheme.outlineVariant),
              const SizedBox(height: 10),
              Text('Không có giao dịch tháng này',
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    // Sort by date descending
    final sorted = [...transactions]..sort((a, b) => b.date.compareTo(a.date));

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: sorted.asMap().entries.map((entry) {
          final idx = entry.key;
          final tx = entry.value;
          final isLast = idx == sorted.length - 1;
          final catColor = CategoryHelper.colorFor(tx.category);

          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.vertical(
                    top: idx == 0 ? const Radius.circular(16) : Radius.zero,
                    bottom: isLast ? const Radius.circular(16) : Radius.zero,
                  ),
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    child: Row(
                      children: [
                        // Date badge
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                tx.date.day.toString(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: catColor,
                                  height: 1,
                                ),
                              ),
                              Text(
                                'Th${tx.date.month}',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: catColor.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Category icon
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CategoryHelper.iconFor(tx.category),
                            color: catColor,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tx.category,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatCurrency(tx.amount, prefix: tx.isIncome ? '+' : '-'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: tx.isIncome ? const Color(0xFF22B45E) : const Color(0xFFFF5252),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 62,
                  color: scheme.outlineVariant.withValues(alpha: 0.3),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
