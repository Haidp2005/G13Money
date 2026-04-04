import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/services/ai_finance_service.dart';
import '../../../core/services/auth_service.dart';
import '../../accounts/data/accounts_repository.dart';
import '../../accounts/data/categories_repository.dart';
import '../../accounts/models/account.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../shared/widgets/category_helper.dart';
import '../../transactions/data/transactions_repository.dart';
import '../../transactions/models/transaction.dart';
import 'ai_chat_page.dart';
import '../state/overview_state.dart';


class OverviewPage extends ConsumerStatefulWidget {
  const OverviewPage({super.key, this.showBottomNav = true});

  final bool showBottomNav;

  @override
  ConsumerState<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends ConsumerState<OverviewPage> {
  bool _aiLoading = false;
  String? _aiAdvice;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadOverviewData();
    });
  }

  Future<void> _loadOverviewData() async {
    ref.read(overviewLoadingProvider.notifier).state = true;
    ref.read(overviewErrorProvider.notifier).state = null;

    try {
      await Future.wait([
        AccountsRepository.instance.loadAccounts(forceRefresh: true),
        TransactionsRepository.instance.loadTransactions(forceRefresh: true),
        CategoriesRepository.instance.loadCategories(forceRefresh: true),
      ]);

      ref.read(overviewWalletsProvider.notifier).state =
          List<Account>.unmodifiable(AccountsRepository.instance.accounts);
      ref.read(overviewTransactionsProvider.notifier).state =
          List<MoneyTransaction>.unmodifiable(
            TransactionsRepository.instance.transactions,
          );
      ref.read(overviewLoadingProvider.notifier).state = false;
    } catch (e) {
      ref.read(overviewLoadingProvider.notifier).state = false;
      ref.read(overviewErrorProvider.notifier).state =
          e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> _generateAiAdvice(
    List<MoneyTransaction> transactions,
    List<Account> wallets,
  ) async {
    setState(() {
      _aiLoading = true;
    });

    final advice = await AiFinanceService.generateAdvice(
      transactions: transactions,
      wallets: wallets,
    );

    if (!mounted) return;
    setState(() {
      _aiAdvice = advice;
      _aiLoading = false;
    });
  }

  List<_ChartData> _chartData(int selectedPeriod, List<MoneyTransaction> transactions) {
    return selectedPeriod == 0
        ? _buildWeeklyChartData(transactions)
        : _buildMonthlyChartData(transactions);
  }

  List<_ChartData> _buildMonthlyChartData(List<MoneyTransaction> transactions) {
    final now = DateTime.now();
    final monthStarts = List<DateTime>.generate(
      6,
      (index) => DateTime(now.year, now.month - (5 - index), 1),
    );

    return monthStarts.map((start) {
      final end = DateTime(start.year, start.month + 1, 1);
      final income = transactions
          .where((tx) =>
              !tx.date.isBefore(start) && tx.date.isBefore(end) && tx.isIncome)
          .fold<double>(0, (sum, tx) => sum + tx.amount);
      final expense = transactions
          .where((tx) =>
              !tx.date.isBefore(start) && tx.date.isBefore(end) && !tx.isIncome)
          .fold<double>(0, (sum, tx) => sum + tx.amount);
      return _ChartData(
        label: 'T${start.month}',
        income: income / 1000000,
        expense: expense / 1000000,
      );
    }).toList(growable: false);
  }

  List<_ChartData> _buildWeeklyChartData(List<MoneyTransaction> transactions) {
    final today = DateTime.now();
    final days = List<DateTime>.generate(
      7,
      (index) {
        final date = today.subtract(Duration(days: 6 - index));
        return DateTime(date.year, date.month, date.day);
      },
    );

    return days.map((day) {
      final nextDay = day.add(const Duration(days: 1));
      final income = transactions
          .where((tx) =>
              !tx.date.isBefore(day) && tx.date.isBefore(nextDay) && tx.isIncome)
          .fold<double>(0, (sum, tx) => sum + tx.amount);
      final expense = transactions
          .where((tx) =>
              !tx.date.isBefore(day) && tx.date.isBefore(nextDay) && !tx.isIncome)
          .fold<double>(0, (sum, tx) => sum + tx.amount);
      return _ChartData(
        label: '${day.day}/${day.month}',
        income: income / 1000000,
        expense: expense / 1000000,
      );
    }).toList(growable: false);
  }

  String _formatCurrency(double value) {
    final raw = value.abs().toStringAsFixed(0);
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(raw[i]);
    }
    final sign = value < 0 ? '-' : '';
    return '$sign${buffer.toString()} đ';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} tháng ${date.month} ${date.year}';
  }

  IconData _walletIcon(String type) {
    switch (type) {
      case 'bank':
        return Icons.account_balance_rounded;
      case 'ewallet':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.payments_rounded;
    }
  }

  Color _walletColor(String type) {
    switch (type) {
      case 'bank':
        return const Color(0xFF3A86FF);
      case 'ewallet':
        return const Color(0xFF6C63FF);
      default:
        return const Color(0xFFF09928);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedPeriod = ref.watch(overviewSelectedPeriodProvider);
    final isLoading = ref.watch(overviewLoadingProvider);
    final loadError = ref.watch(overviewErrorProvider);
    final wallets = ref.watch(overviewWalletsProvider);
    final transactions = ref.watch(overviewTransactionsProvider);

    final totalBalance = wallets.fold<double>(0, (sum, item) => sum + item.balance);
    final totalIncome = transactions
      .where((item) => item.isIncome)
      .fold<double>(0, (sum, item) => sum + item.amount);
    final totalExpense = transactions
      .where((item) => !item.isIncome)
      .fold<double>(0, (sum, item) => sum + item.amount);

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
          : loadError != null
            ? _buildErrorState(scheme, loadError)
                : RefreshIndicator(
                    onRefresh: _loadOverviewData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(scheme),
                          const SizedBox(height: 24),
                          _buildBalanceCard(
                            scheme,
                            totalBalance,
                            totalIncome,
                            totalExpense,
                          ),
                          const SizedBox(height: 24),
                          _buildAiSuggestionSection(
                            scheme,
                            transactions,
                            wallets,
                          ),
                          const SizedBox(height: 24),
                          _buildReportSection(
                            scheme,
                            selectedPeriod,
                            totalIncome,
                            totalExpense,
                            _chartData(selectedPeriod, transactions),
                          ),
                          const SizedBox(height: 24),
                          _buildWalletSection(scheme, wallets),
                          const SizedBox(height: 24),
                          _buildRecentTransactionsSection(scheme, transactions),
                        ],
                      ),
                    ),
                  ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? MoneyBottomNav(currentIndex: 0, onItemTap: (_) {}, onAddTap: () {})
          : null,
    );
  }

  Widget _buildErrorState(ColorScheme scheme, String loadError) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42),
            const SizedBox(height: 10),
            Text(
              'Không tải được dữ liệu overview',
              style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              loadError,
              style: TextStyle(color: scheme.outline),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadOverviewData,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme scheme) {
    final fullName = AuthService.currentUser?.fullName.trim();
    final displayName = (fullName == null || fullName.isEmpty) ? 'G13 Money' : fullName;
    final avatarText = (displayName.isNotEmpty ? displayName[0] : 'G').toUpperCase();

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
          child: Center(
            child: Text(
              avatarText,
              style: const TextStyle(
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
                displayName,
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
        _headerIconButton(
          Icons.notifications_none_rounded,
          scheme,
          onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
        ),
      ],
    );
  }

  Widget _headerIconButton(IconData icon, ColorScheme scheme, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }

  Widget _buildBalanceCard(
    ColorScheme scheme,
    double totalBalance,
    double totalIncome,
    double totalExpense,
  ) {
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
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _formatCurrency(totalBalance),
            style: const TextStyle(
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
                value: _formatCurrency(totalIncome),
              ),
              const SizedBox(width: 12),
              _balanceSummaryChip(
                icon: Icons.arrow_downward_rounded,
                label: 'Chi tiêu',
                value: _formatCurrency(totalExpense),
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
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
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

  Widget _buildReportSection(
    ColorScheme scheme,
    int selectedPeriod,
    double totalIncome,
    double totalExpense,
    List<_ChartData> chartData,
  ) {
    final maxSeries = chartData.fold<double>(1, (maxSoFar, item) {
      final localMax = item.income > item.expense ? item.income : item.expense;
      return localMax > maxSoFar ? localMax : maxSoFar;
    });
    final chartMaxY = (maxSeries * 1.2).clamp(1, 999999).toDouble();
    final interval = chartMaxY <= 4 ? 1.0 : (chartMaxY / 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: 'Báo cáo',
          action: 'Xem báo cáo',
          scheme: scheme,
          onTap: () => Navigator.pushNamed(context, AppRoutes.reports),
        ),
        const SizedBox(height: 14),
        _sectionCard(
          scheme: scheme,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPeriodSwitch(scheme, selectedPeriod),
              const SizedBox(height: 14),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: chartMaxY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: interval,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: scheme.outlineVariant.withValues(alpha: 0.3),
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= chartData.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                chartData[i].label,
                                style: TextStyle(color: scheme.outline, fontSize: 11),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: interval,
                          getTitlesWidget: (value, meta) => Text(
                            '${value.toInt()}tr',
                            style: TextStyle(color: scheme.outline, fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                    barGroups: chartData.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barsSpace: 4,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.income,
                            color: scheme.primary,
                            width: 12,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                          BarChartRodData(
                            toY: entry.value.expense,
                            color: const Color(0xFFFF6B6B),
                            width: 12,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ],
                      );
                    }).toList(growable: false),
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
                          Text('Tổng thu', style: TextStyle(color: scheme.outline, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            _formatCurrency(totalIncome),
                            style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30, child: VerticalDivider(color: scheme.outlineVariant)),
                    Expanded(
                      child: Column(
                        children: [
                          Text('Tổng chi', style: TextStyle(color: scheme.outline, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            _formatCurrency(totalExpense),
                            style: const TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.w700),
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

  Widget _buildAiSuggestionSection(
    ColorScheme scheme,
    List<MoneyTransaction> transactions,
    List<Account> wallets,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: 'Gợi ý tài chính AI',
          action: 'Tạo mới',
          scheme: scheme,
          onTap: () => _generateAiAdvice(transactions, wallets),
        ),
        const SizedBox(height: 14),
        _sectionCard(
          scheme: scheme,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nhận 3 gợi ý hành động dựa trên dữ liệu thu chi của bạn',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_aiLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(minHeight: 6),
                ),
              if (!_aiLoading && (_aiAdvice == null || _aiAdvice!.trim().isEmpty))
                Text(
                  'Nhấn "Tạo gợi ý AI" để nhận tư vấn tài chính cá nhân hoá.',
                  style: TextStyle(color: scheme.outline, fontSize: 13),
                ),
              if (!_aiLoading && _aiAdvice != null && _aiAdvice!.trim().isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _aiAdvice!,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _aiLoading
                          ? null
                          : () => _generateAiAdvice(transactions, wallets),
                      icon: const Icon(Icons.psychology_alt_outlined),
                      label: Text(
                        AiFinanceService.isConfigured
                            ? 'Tạo gợi ý AI'
                            : 'Tạo gợi ý (local + AI)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _aiLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AiChatPage(
                                    transactions: transactions,
                                    wallets: wallets,
                                  ),
                                ),
                              );
                            },
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text('Chat AI'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWalletSection(ColorScheme scheme, List<Account> wallets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(title: 'Ví của tôi', action: 'Xem tất cả', scheme: scheme),
        const SizedBox(height: 14),
        _sectionCard(
          scheme: scheme,
          child: wallets.isEmpty
              ? Text('Chưa có ví', style: TextStyle(color: scheme.outline))
              : Column(
                  children: wallets.asMap().entries.map((entry) {
                    final isLast = entry.key == wallets.length - 1;
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
                  }).toList(growable: false),
                ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsSection(
    ColorScheme scheme,
    List<MoneyTransaction> transactions,
  ) {
    final recent = transactions.take(6).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(title: 'Giao dịch gần đây', action: 'Xem tất cả', scheme: scheme),
        const SizedBox(height: 14),
        _sectionCard(
          scheme: scheme,
          child: recent.isEmpty
              ? Text('Chưa có giao dịch', style: TextStyle(color: scheme.outline))
              : Column(
                  children: recent.asMap().entries.map((entry) {
                    final isLast = entry.key == recent.length - 1;
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
                  }).toList(growable: false),
                ),
        ),
      ],
    );
  }

  Widget _walletTile(Account item, ColorScheme scheme) {
    final color = _walletColor(item.type);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_walletIcon(item.type), color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              item.name,
              style: TextStyle(color: scheme.onSurface, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            _formatCurrency(item.balance),
            style: TextStyle(color: scheme.onSurface, fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _transactionTile(MoneyTransaction item, ColorScheme scheme) {
    final categoryColor = CategoryHelper.colorFor(item.category);
    final amountColor = item.isIncome ? const Color(0xFF2DCC5A) : const Color(0xFFFF6B6B);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(CategoryHelper.iconFor(item.category), color: categoryColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(color: scheme.onSurface, fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatDate(item.date),
                  style: TextStyle(color: scheme.outline, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${item.isIncome ? '+' : '-'}${_formatCurrency(item.amount).replaceAll(' đ', '')}',
            style: TextStyle(color: amountColor, fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSwitch(ColorScheme scheme, int selectedPeriod) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _periodTab('Tuần', 0, scheme, selectedPeriod),
          _periodTab('Tháng', 1, scheme, selectedPeriod),
        ],
      ),
    );
  }

  Widget _periodTab(
    String label,
    int index,
    ColorScheme scheme,
    int selectedPeriod,
  ) {
    final isSelected = selectedPeriod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () =>
            ref.read(overviewSelectedPeriodProvider.notifier).state = index,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
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
      ),
      child: child,
    );
  }

  Widget _sectionHeader({
    required String title,
    required String action,
    required ColorScheme scheme,
    VoidCallback? onTap,
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
          onTap: onTap,
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
              Icon(Icons.arrow_forward_ios_rounded, color: scheme.primary, size: 12),
            ],
          ),
        ),
      ],
    );
  }
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

