import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'reports_screen.dart';
import 'transaction_detail_page.dart';
import '../models/transaction.dart';
import '../state/transaction_filter_state.dart';
import '../state/transactions_provider.dart';
import '../../shared/widgets/category_helper.dart';
import '../../../core/services/language_service.dart';
import '../../../core/state/app_settings_providers.dart';
import '../../../core/services/connectivity_service.dart';
import '../../shared/widgets/no_network_widget.dart';

class TransactionScreen extends ConsumerStatefulWidget {
  const TransactionScreen({super.key});

  @override
  ConsumerState<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends ConsumerState<TransactionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _SearchScope _searchScope = _SearchScope.all;

  List<Map<String, dynamic>> _groupTransactions(
    List<MoneyTransaction> transactions,
  ) {
    final groups = <String, List<MoneyTransaction>>{};
    for (final transaction in transactions) {
      final key = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      ).toIso8601String();
      groups.putIfAbsent(key, () => <MoneyTransaction>[]).add(transaction);
    }

    final sortedKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    final result = <Map<String, dynamic>>[];

    for (final key in sortedKeys) {
      final txList = groups[key]!;
      final date = DateTime.parse(key);
      final net = txList.fold<double>(0, (sum, tx) {
        return sum + (tx.isIncome ? tx.amount : -tx.amount);
      });

      result.add({
        'dateStr': _formatDateGroup(date),
        'totalAmount': _formatGroupAmount(net),
        'isIncome': net >= 0,
        'transactions': txList
            .map(
              (tx) => {
                'tx': tx,
                'icon': CategoryHelper.iconFor(tx.category),
                'categoryColor': CategoryHelper.colorFor(tx.category),
                'title': tx.title,
                'note': tx.category,
                'amount': tx.amount,
                'isIncome': tx.isIncome,
              },
            )
            .toList(growable: false),
      });
    }

    return result;
  }

  String _formatDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final current = DateTime(date.year, date.month, date.day);
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    if (current == today) {
      return '${LanguageService.tr(vi: 'Hôm nay', en: 'Today')}, $day/$month/${date.year}';
    }
    if (current == yesterday) {
      return '${LanguageService.tr(vi: 'Hôm qua', en: 'Yesterday')}, $day/$month/${date.year}';
    }
    return '$day/$month/${date.year}';
  }

  String _formatGroupAmount(double value) {
    final absValue = value.abs().toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < absValue.length; i++) {
      if (i > 0 && (absValue.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(absValue[i]);
    }
    return '${value >= 0 ? '+' : '-'}${buffer.toString()} ₫';
  }

  List<MoneyTransaction> _applyFilters(
    List<MoneyTransaction> transactions,
    int selectedFilterIndex,
    DateTimeRange? customRange,
    String rawQuery,
    _SearchScope searchScope,
  ) {
    final now = DateTime.now();
    final query = rawQuery.trim().toLowerCase();

    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);

    final endOfCustomRange = customRange == null
        ? null
        : DateTime(
            customRange.end.year,
            customRange.end.month,
            customRange.end.day,
            23,
            59,
            59,
          );

    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    return transactions.where((tx) {
      final dateOnly = DateTime(tx.date.year, tx.date.month, tx.date.day);

      final matchesTime = switch (selectedFilterIndex) {
        0 => !dateOnly.isBefore(startOfMonth) && dateOnly.isBefore(endOfMonth),
        1 => !dateOnly.isBefore(startOfWeek) && dateOnly.isBefore(endOfWeek),
        2 => customRange != null &&
            !tx.date.isBefore(customRange.start) &&
            !tx.date.isAfter(endOfCustomRange!),
        _ => true,
      };
      if (!matchesTime) return false;

      if (query.isEmpty) return true;
      final note = tx.title.toLowerCase();
      final category = tx.category.toLowerCase();
      return switch (searchScope) {
        _SearchScope.category => category.contains(query),
        _SearchScope.note => note.contains(query),
        _SearchScope.all => note.contains(query) || category.contains(query),
      };
    }).toList(growable: false);
  }

  String _customRangeLabel(DateTimeRange range) {
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    return '${fmt(range.start)} - ${fmt(range.end)}';
  }

  String _searchHintText() {
    return switch (_searchScope) {
      _SearchScope.category => LanguageService.tr(vi: 'Tìm theo danh mục...', en: 'Search by category...'),
      _SearchScope.note => LanguageService.tr(vi: 'Tìm theo ghi chú...', en: 'Search by note...'),
      _SearchScope.all => LanguageService.tr(vi: 'Tìm theo ghi chú hoặc danh mục...', en: 'Search by note or category...'),
    };
  }

  String _searchScopeLabel() {
    return switch (_searchScope) {
      _SearchScope.category => LanguageService.tr(vi: 'Danh mục', en: 'Category'),
      _SearchScope.note => LanguageService.tr(vi: 'Ghi chú', en: 'Note'),
      _SearchScope.all => LanguageService.tr(vi: 'Ghi chú + Danh mục', en: 'Note + Category'),
    };
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appLanguageProvider); // Rebuild on language change
    final scheme = Theme.of(context).colorScheme;
    final selectedFilterIndex = ref.watch(transactionFilterIndexProvider);
    final customRange = ref.watch(transactionCustomDateRangeProvider);
    final transactionState = ref.watch(transactionsControllerProvider);
    final remoteTransactions =
      transactionState.valueOrNull ?? <MoneyTransaction>[];
    final filteredTransactions = _applyFilters(
      remoteTransactions,
      selectedFilterIndex,
      customRange,
      _searchQuery,
      _searchScope,
    );
    final groupedData = _groupTransactions(filteredTransactions);

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: scheme.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0.5,
            shadowColor: scheme.shadow.withValues(alpha: 0.2),
            title: Text(
              LanguageService.tr(vi: 'Sổ giao dịch', en: 'Transactions'),
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(156),
              child: Column(
                children: [
                  // ── Search Bar ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: _searchHintText(),
                          hintStyle: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 15,
                          ),
                          prefixIcon: Icon(Icons.search, color: scheme.onSurfaceVariant),
                          suffixIcon: PopupMenuButton<_SearchScope>(
                            tooltip: LanguageService.tr(vi: 'Chọn phạm vi tìm kiếm', en: 'Select search scope'),
                            initialValue: _searchScope,
                            onSelected: (value) {
                              setState(() {
                                _searchScope = value;
                              });
                            },
                            icon: Icon(
                              Icons.tune,
                              color: scheme.onSurfaceVariant,
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: _SearchScope.all,
                                child: Text(LanguageService.tr(vi: 'Ghi chú + Danh mục', en: 'Note + Category')),
                              ),
                              PopupMenuItem(
                                value: _SearchScope.category,
                                child: Text(LanguageService.tr(vi: 'Danh mục', en: 'Category')),
                              ),
                              PopupMenuItem(
                                value: _SearchScope.note,
                                child: Text(LanguageService.tr(vi: 'Ghi chú', en: 'Note')),
                              ),
                            ],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 2),
                    child: Row(
                      children: [
                        Text(
                          '${LanguageService.tr(vi: 'Tìm theo', en: 'Search by')}: ${_searchScopeLabel()}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        if (selectedFilterIndex == 2 && customRange != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${LanguageService.tr(vi: 'Khoảng', en: 'Range')}: ${_customRangeLabel(customRange)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: scheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // ── Filter Bar ──
                  _FilterBar(
                    onFilterChanged: (_) {},
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Report Button ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReportsScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: scheme.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: scheme.primary.withValues(alpha: 0.04),
                  ),
                  child: Text(
                    LanguageService.tr(vi: 'Xem báo cáo cho giai đoạn này', en: 'View report for this period'),
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (transactionState.hasError)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: transactionState.error is OfflineException
                  ? NoNetworkWidget(
                      compact: true,
                      onRetry: () => ref.read(transactionsControllerProvider.notifier).refresh(),
                    )
                  : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        LanguageService.tr(vi: 'Không thể tải giao dịch mới nhất. Vui lòng thử lại.', en: 'Could not load latest transactions. Please try again.'),
                        style: TextStyle(
                          color: scheme.onErrorContainer,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
              ),
            ),

          // ── Transaction List ──
          if (groupedData.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: Text(
                  LanguageService.tr(vi: 'Không có giao dịch phù hợp bộ lọc hiện tại.', en: 'No transactions match the current filter.'),
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 100), // padding for FAB
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, groupIndex) {
                  final group = groupedData[groupIndex];
                  final transactions = group['transactions'] as List<Map<String, dynamic>>;

                  return Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                        _DateHeader(
                          dateStr: group['dateStr'],
                          totalAmount: group['totalAmount'],
                          isIncome: group['isIncome'],
                        ),
                        ...transactions.map((tx) => _TransactionItem(
                          icon: tx['icon'],
                          categoryColor: tx['categoryColor'],
                          title: tx['title'],
                          note: tx['note'],
                          amount: tx['amount'],
                          isIncome: tx['isIncome'],
                          onTap: () async {
                            final original = tx['tx'] as MoneyTransaction;
                            final changed = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TransactionDetailPage(
                                  transaction: original,
                                ),
                              ),
                            );
                            if (changed == true) {
                              await ref
                                  .read(transactionsControllerProvider.notifier)
                                  .refresh();
                            }
                          },
                        )),
                     ],
                  );
                },
                childCount: groupedData.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _SearchScope { all, category, note }

// ── Widget: FilterBar ──
class _FilterBar extends ConsumerWidget {
  final Function(String)? onFilterChanged;

  const _FilterBar({this.onFilterChanged});

  static List<String> get _filters => [
    LanguageService.tr(vi: 'Tháng này', en: 'This month'),
    LanguageService.tr(vi: 'Tuần này', en: 'This week'),
    LanguageService.tr(vi: 'Tùy chỉnh', en: 'Custom'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(transactionFilterIndexProvider);
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                _filters[index],
                style: TextStyle(
                  color: isSelected ? scheme.onPrimary : scheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  if (index == 2) {
                    () async {
                      final now = DateTime.now();
                      final initialRange =
                          ref.read(transactionCustomDateRangeProvider) ??
                          DateTimeRange(
                            start: DateTime(now.year, now.month, 1),
                            end: DateTime(now.year, now.month, now.day),
                          );

                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDateRange: initialRange,
                        saveText: LanguageService.tr(vi: 'Áp dụng', en: 'Apply'),
                        helpText: LanguageService.tr(vi: 'Chọn khoảng thời gian', en: 'Select time range'),
                      );

                      if (picked == null) return;
                      ref
                          .read(transactionCustomDateRangeProvider.notifier)
                          .state = picked;
                      ref.read(transactionFilterIndexProvider.notifier).state =
                          index;
                      if (onFilterChanged != null) {
                        onFilterChanged!(_filters[index]);
                      }
                    }();
                    return;
                  }

                    ref.read(transactionFilterIndexProvider.notifier).state =
                      index;
                  if (onFilterChanged != null) {
                    onFilterChanged!(_filters[index]);
                  }
                }
              },
              backgroundColor: scheme.surfaceContainerHighest,
              selectedColor: scheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? scheme.primary : Colors.transparent,
                ),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }
}

// ── Widget: DateHeader ──
class _DateHeader extends StatelessWidget {
  final String dateStr;
  final String totalAmount;
  final bool isIncome;

  const _DateHeader({
    required this.dateStr,
    required this.totalAmount,
    this.isIncome = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dateStr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          Text(
            totalAmount,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isIncome ? const Color(0xFF2DCC5A) : const Color(0xFFFF6B6B),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget: TransactionItem ──
class _TransactionItem extends StatelessWidget {
  final IconData icon;
  final Color categoryColor;
  final String title;
  final String note;
  final double amount;
  final bool isIncome;
  final VoidCallback? onTap;

  const _TransactionItem({
    required this.icon,
    required this.categoryColor,
    required this.title,
    required this.note,
    required this.amount,
    required this.isIncome,
    this.onTap,
  });

  String _formatCurrency(double value) {
    final absValue = value.abs().toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < absValue.length; i++) {
      if (i > 0 && (absValue.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(absValue[i]);
    }
    return '${isIncome ? '+' : '-'}${buffer.toString()} ₫';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: categoryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                      if (note.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          note,
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ]
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatCurrency(amount),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isIncome ? const Color(0xFF2DCC5A) : const Color(0xFFFF6B6B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
