import 'package:flutter/material.dart';

import '../../accounts/ui/accounts_page.dart';
import '../../budgets/ui/budgets_page.dart';
import '../../overview/ui/overview_page.dart';
import '../../transactions/ui/transaction_screen.dart';
import '../widgets/bottom_nav.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key, this.initialIndex = overviewTab});

  static const int overviewTab = 0;
  static const int transactionsTab = 1;
  static const int budgetsTab = 3;
  static const int profileTab = 4;

  final int initialIndex;

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  late int _selectedIndex;

  final Widget _overviewPage = const OverviewPage(showBottomNav: false);
  final Widget _transactionsPage = const TransactionScreen();
  final Widget _budgetsPage = const BudgetsPage();
  final Widget _profilePage = const ProfilePage();

  @override
  void initState() {
    super.initState();
    _selectedIndex = _normalizeIndex(widget.initialIndex);
  }

  @override
  void didUpdateWidget(covariant MainShellPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _selectedIndex = _normalizeIndex(widget.initialIndex);
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

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
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
    if (index == _selectedIndex) {
      return;
    }
    setState(() {
      _selectedIndex = _normalizeIndex(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentPage(),
      bottomNavigationBar: MoneyBottomNav(
        currentIndex: _selectedIndex,
        onItemTap: _onTapNavItem,
        onAddTap: () {
          setState(() {
            _selectedIndex = MainShellPage.transactionsTab;
          });
        },
      ),
    );
  }
}
