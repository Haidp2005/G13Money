import 'package:flutter/material.dart';

import '../features/budgets/ui/budgets_page.dart';

abstract final class AppRoutes {
  static const String login = '/login';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String budgets = '/budgets';

  static final Map<String, WidgetBuilder> map = {
    budgets: (context) => const BudgetsPage(),
  };
}
