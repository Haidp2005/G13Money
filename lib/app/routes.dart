import 'package:flutter/material.dart';

import '../features/budgets/ui/budgets_page.dart';
import '../features/auth/ui/login_page.dart';
import '../features/overview/ui/overview_page.dart';
import '../features/transactions/ui/transactions_page.dart';

abstract final class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String budgets = '/budgets';
  static const String transactions = '/transactions';

  static final Map<String, WidgetBuilder> map = {
    login: (context) => const LoginPage(),
    home: (context) => const OverviewPage(),
    budgets: (context) => const BudgetsPage(),
    transactions: (context) => const TransactionsPage(),
  };
}
