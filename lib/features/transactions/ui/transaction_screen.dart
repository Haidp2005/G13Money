import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'reports_screen.dart';
import 'add_transaction_form_page.dart';
import '../models/transaction.dart';
import '../state/transaction_filter_state.dart';
import '../state/transactions_provider.dart';
import '../../shared/widgets/category_helper.dart';

class TransactionScreen extends ConsumerStatefulWidget {
  const TransactionScreen({super.key});

  @override
  ConsumerState<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends ConsumerState<TransactionScreen> {
  // Dummy Data for demonstration
  final List<Map<String, dynamic>> _groupedTransactions = [
    {
      'dateStr': 'Hôm nay, 12/03/2026',
      'totalAmount': '-100,000 ₫',
      'isIncome': false,
      'transactions': [
        {
          'icon': Icons.local_cafe,
          'categoryColor': Colors.orange,
          'title': 'Cà phê sáng',
          'note': 'Cà phê với đối tác',
          'amount': 45000.0,
          'isIncome': false,
        },
        {
          'icon': Icons.directions_bus,
          'categoryColor': Colors.blue,
          'title': 'Xe buýt',
          'note': 'Vé tháng',
          'amount': 55000.0,
          'isIncome': false,
        },
      ]
    },
    {
      'dateStr': 'Hôm qua, 11/03/2026',
      'totalAmount': '+12,500,000 ₫',
      'isIncome': true,
      'transactions': [
        {
          'icon': Icons.monetization_on,
          'categoryColor': Colors.green,
          'title': 'Lương tháng',
          'note': 'Lương tháng 3/2026',
          'amount': 15000000.0,
          'isIncome': true,
        },
        {
          'icon': Icons.shopping_cart,
          'categoryColor': Colors.redAccent,
          'title': 'Siêu thị',
          'note': 'Mua đồ ăn tuần',
          'amount': 2500000.0,
          'isIncome': false,
        },
      ]
    },
    {
      'dateStr': '10/03/2026',
      'totalAmount': '-200,000 ₫',
      'isIncome': false,
      'transactions': [
        {
          'icon': Icons.movie,
          'categoryColor': Colors.purple,
          'title': 'Xem phim',
          'note': 'CGV Landmark',
          'amount': 200000.0,
          'isIncome': false,
        },
      ]
    }
  ];

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
      return 'Hôm nay, $day/$month/${date.year}';
    }
    if (current == yesterday) {
      return 'Hôm qua, $day/$month/${date.year}';
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final transactionState = ref.watch(transactionsControllerProvider);
    final remoteTransactions =
      transactionState.valueOrNull ?? <MoneyTransaction>[];
    final groupedData = remoteTransactions.isEmpty
        ? _groupedTransactions
        : _groupTransactions(remoteTransactions);

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
              'Sổ giao dịch',
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.more_horiz, color: scheme.onSurfaceVariant),
                onPressed: () {},
              )
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(130),
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
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm giao dịch...',
                          hintStyle: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 15,
                          ),
                          prefixIcon: Icon(Icons.search, color: scheme.onSurfaceVariant),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
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
                    'Xem báo cáo cho giai đoạn này',
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
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Không thể tải giao dịch mới nhất. Đang hiển thị dữ liệu cục bộ.',
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
                            final updated = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddTransactionFormPage(
                                  initialData: TransactionFormInitialData(
                                    transactionId: original.id,
                                    note: original.title,
                                    walletName: original.walletName,
                                    category: original.category,
                                    amount: original.amount,
                                    date: original.date,
                                    isIncome: original.isIncome,
                                  ),
                                ),
                              ),
                            );
                            if (updated == true) {
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

// ── Widget: FilterBar ──
class _FilterBar extends ConsumerWidget {
  final Function(String)? onFilterChanged;

  const _FilterBar({this.onFilterChanged});

  static const List<String> _filters = ['Tháng này', 'Tuần này', 'Tùy chỉnh'];

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
