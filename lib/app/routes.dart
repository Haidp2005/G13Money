import 'package:flutter/material.dart';

import '../features/accounts/ui/accounts_page.dart';
import '../features/accounts/ui/edit_profile_page.dart';
import '../features/budgets/ui/budgets_page.dart';
import '../features/auth/ui/login_page.dart';
import '../features/shared/ui/main_shell_page.dart';

abstract final class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String budgets = '/budgets';

  static final Map<String, WidgetBuilder> map = {
    login: (context) => const LoginPage(),
    home: (context) {
      final Object? args = ModalRoute.of(context)?.settings.arguments;
      final int initialIndex = args is int ? args : MainShellPage.overviewTab;
      return MainShellPage(initialIndex: initialIndex);
    },
    profile: (context) => const ProfilePage(),
    editProfile: (context) => const EditProfilePage(),
    budgets: (context) => const BudgetsPage(),
  };
}
