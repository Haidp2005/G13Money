import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accounts/data/accounts_repository.dart';
import '../../accounts/models/account.dart';
import '../../accounts/state/manage_wallets_state.dart';
import '../../accounts/ui/accounts_page.dart';
import '../../budgets/models/budget.dart';
import '../../budgets/state/budgets_state.dart';
import '../../budgets/ui/budgets_page.dart';
import '../../overview/state/overview_state.dart';
import '../../overview/ui/overview_page.dart';
import '../../transactions/data/transactions_repository.dart';
import '../../transactions/models/transaction.dart';
import '../../transactions/ui/add_transaction_form_page.dart';
import '../../transactions/ui/transaction_screen.dart';
import '../../transactions/state/transactions_provider.dart';
import '../state/main_shell_state.dart';
import '../widgets/bottom_nav.dart';

class MainShellPage extends ConsumerStatefulWidget {
  const MainShellPage({super.key, this.initialIndex = overviewTab});

  static const int overviewTab = 0;
  static const int transactionsTab = 1;
  static const int budgetsTab = 3;
  static const int profileTab = 4;

  final int initialIndex;

  @override
  ConsumerState<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends ConsumerState<MainShellPage> {
  Timer? _syncTimer;
  bool _syncInProgress = false;

  final Widget _overviewPage = const OverviewPage(showBottomNav: false);
  final Widget _transactionsPage = const TransactionScreen();
  final Widget _budgetsPage = const BudgetsPage();
  final Widget _profilePage = const ProfilePage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(shellSelectedIndexProvider.notifier).state =
          _normalizeIndex(widget.initialIndex);
      _startAutoSync();
      _syncAllData();
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MainShellPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(shellSelectedIndexProvider.notifier).state =
            _normalizeIndex(widget.initialIndex);
      });
    }
  }

  int _normalizeIndex(int index) {
    const validTabs = <int>{
      MainShellPage.overviewTab,
      MainShellPage.transactionsTab,
      MainShellPage.budgetsTab,
      MainShellPage.profileTab,
    };
    return validTabs.contains(index) ? index : MainShellPage.overviewTab;
  }

  void _startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      _syncAllData();
    });
  }

  Future<void> _syncAllData() async {
    if (_syncInProgress) return;
    _syncInProgress = true;

    try {
      await Future.wait([
        AccountsRepository.instance.loadAccounts(forceRefresh: true),
        TransactionsRepository.instance.loadTransactions(forceRefresh: true),
      ]);

      if (!mounted) return;

      final accounts = AccountsRepository.instance.accounts;
      final transactions = TransactionsRepository.instance.transactions;

      ref.read(overviewWalletsProvider.notifier).state =
          List<Account>.unmodifiable(accounts);
      ref.read(overviewTransactionsProvider.notifier).state =
          List<MoneyTransaction>.unmodifiable(transactions);

      ref.invalidate(walletsProvider);
      ref.invalidate(transactionsControllerProvider);

      final currentBudgets = ref.read(budgetsListProvider);
      if (currentBudgets.isNotEmpty) {
        // Force a rebuild so budget spent values recalc from refreshed transactions.
        ref.read(budgetsListProvider.notifier).state =
            List<Budget>.unmodifiable(currentBudgets);
      }
    } finally {
      _syncInProgress = false;
    }
  }

  Widget _buildCurrentPage() {
    final selectedIndex = ref.read(shellSelectedIndexProvider);
    switch (selectedIndex) {
      case MainShellPage.overviewTab:
        return _overviewPage;
      case MainShellPage.transactionsTab:
        return _transactionsPage;
      case MainShellPage.budgetsTab:
        return _budgetsPage;
      case MainShellPage.profileTab:
        return _profilePage;
      default:
        return _overviewPage;
    }
  }

  void _onTapNavItem(int index) {
    final selectedIndex = ref.read(shellSelectedIndexProvider);
    if (index == selectedIndex) {
      return;
    }
    ref.read(shellSelectedIndexProvider.notifier).state =
        _normalizeIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(shellSelectedIndexProvider);
    return Scaffold(
      body: _buildCurrentPage(),
      bottomNavigationBar: MoneyBottomNav(
        currentIndex: selectedIndex,
        onItemTap: _onTapNavItem,
        onAddTap: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const AddTransactionFormPage(),
            ),
          );
          if (created == true && mounted) {
            await _syncAllData();
          }
        },
      ),
    );
  }
}
