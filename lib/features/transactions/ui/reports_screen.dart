import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../shared/widgets/category_helper.dart';
import '../../accounts/data/accounts_repository.dart';
import '../../accounts/data/categories_repository.dart';
import '../models/transaction.dart';
import '../data/transactions_repository.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _touchedIncomeIndex = -1;
  int _touchedExpenseIndex = -1;

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
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    // Fetch data
    final transactions = TransactionsRepository.instance.transactions;
    final incomeTx = transactions.where((t) => t.isIncome).toList();
    final expenseTx = transactions.where((t) => !t.isIncome).toList();

    final totalIncome = incomeTx.fold<double>(0, (sum, t) => sum + t.amount);
    final totalExpense = expenseTx.fold<double>(0, (sum, t) => sum + t.amount);
    final totalBalance = AccountsRepository.instance.accounts
      .fold<double>(0, (sum, account) => sum + account.balance);

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          'Báo cáo giai đoạn',
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        shadowColor: scheme.shadow.withValues(alpha: 0.2),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Section ──
              _buildHeaderSection(scheme, totalBalance),
              const SizedBox(height: 24),

              // ── Chart Section ──
              Text(
                'Tổng quan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDonutChartCard(
                      scheme: scheme,
                      title: 'Thu nhập',
                      amount: totalIncome,
                      isIncome: true,
                      transactions: incomeTx,
                      touchedIndex: _touchedIncomeIndex,
                      onTouched: (idx) {
                        setState(() {
                          _touchedIncomeIndex = idx;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDonutChartCard(
                      scheme: scheme,
                      title: 'Chi tiêu',
                      amount: totalExpense,
                      isIncome: false,
                      transactions: expenseTx,
                      touchedIndex: _touchedExpenseIndex,
                      onTouched: (idx) {
                        setState(() {
                          _touchedExpenseIndex = idx;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── List Section ──
              Text(
                'Chi tiết giao dịch',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _buildSimpleTransactionGroup(scheme, 'Tất cả Giao dịch', transactions),
              _buildSimpleTransactionGroup(scheme, 'Nợ & Cho vay', []), 
              _buildSimpleTransactionGroup(scheme, 'Khác', []),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header Component ──
  Widget _buildHeaderSection(ColorScheme scheme, double totalBalance) {
    return Column(
      children: [
        Column(
          children: [
            Text(
              'Số dư hiện tại',
              style: TextStyle(
                fontSize: 14,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatCurrency(totalBalance),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 0,
          color: scheme.primaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: scheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.star_rounded, color: scheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Khai thác tối đa Premium',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        'Xem báo cáo không giới hạn',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: scheme.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Chart Component ──
  Widget _buildDonutChartCard({
    required ColorScheme scheme,
    required String title,
    required double amount,
    required bool isIncome,
    required List<MoneyTransaction> transactions,
    required int touchedIndex,
    required Function(int) onTouched,
  }) {
    // Group transactions by category to calculate pie chart slices
    final Map<String, double> categorySums = {};
    for (var tx in transactions) {
      categorySums[tx.category] = (categorySums[tx.category] ?? 0) + tx.amount;
    }

    final categories = categorySums.keys.toList();
    final noData = categories.isEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isIncome ? const Color(0xFF2DCC5A) : const Color(0xFFFF6B6B),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
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
                    sectionsSpace: 2,
                    centerSpaceRadius: 35,
                    sections: noData
                        ? [
                            PieChartSectionData(
                              color: scheme.surfaceContainerHighest,
                              value: 1,
                              title: '',
                              radius: 12,
                            )
                          ]
                        : categories.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final category = entry.value;
                            final value = categorySums[category]!;
                            final isTouched = idx == touchedIndex;
                            final radius = isTouched ? 18.0 : 12.0;

                            return PieChartSectionData(
                              color: CategoryHelper.colorFor(category),
                              value: value,
                              title: '',
                              radius: radius,
                            );
                          }).toList(),
                  ),
                ),
                // Show percentage in the middle
                if (!noData && touchedIndex != -1 && touchedIndex < categories.length)
                  Text(
                    '${((categorySums[categories[touchedIndex]]! / amount) * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── List Component ──
  Widget _buildSimpleTransactionGroup(ColorScheme scheme, String groupName, List<MoneyTransaction> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            groupName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final idx = entry.key;
              final tx = entry.value;
              final isLast = idx == items.length - 1;

              return Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: CategoryHelper.colorFor(tx.category).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                CategoryHelper.iconFor(tx.category),
                                color: CategoryHelper.colorFor(tx.category),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                tx.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                            Text(
                              _formatCurrency(tx.amount, prefix: tx.isIncome ? '+' : '-'),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: tx.isIncome ? const Color(0xFF2DCC5A) : const Color(0xFFFF6B6B),
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
                      indent: 64,
                      color: scheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double value, {String prefix = ''}) {
    final absValue = value.abs().toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < absValue.length; i++) {
      if (i > 0 && (absValue.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(absValue[i]);
    }
    
    // For net total balance, no prefix if positive/negative (usually formatting handles sign implicitly)
    if (prefix.isNotEmpty) {
      return '$prefix${buffer.toString()} ₫';
    } 
    return '${value < 0 ? "-" : ""}${buffer.toString()} ₫';
  }
}
