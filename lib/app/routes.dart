import 'package:flutter/material.dart';

import '../features/accounts/ui/accounts_page.dart';
import '../features/accounts/ui/change_password_page.dart';
import '../features/accounts/ui/edit_profile_page.dart';
import '../features/accounts/ui/manage_categories_page.dart';
import '../features/accounts/ui/manage_wallets_page.dart';
import '../features/accounts/ui/notification_settings_page.dart';
import '../features/accounts/ui/notifications_page.dart';
import '../features/budgets/ui/budgets_page.dart';
import '../features/auth/ui/login_page.dart';
import '../features/shared/ui/main_shell_page.dart';
import '../features/transactions/ui/reports_screen.dart';

abstract final class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String changePassword = '/change-password';
  static const String notifications = '/notifications';
  static const String notificationSettings = '/notification-settings';
  static const String budgets = '/budgets';
  static const String manageWallets = '/manage-wallets';
  static const String manageCategories = '/manage-categories';
  static const String reports = '/reports';

  static final Map<String, WidgetBuilder> map = {
    login: (context) => const LoginPage(),
    home: (context) {
      final Object? args = ModalRoute.of(context)?.settings.arguments;
      final int initialIndex = args is int ? args : MainShellPage.overviewTab;
      return MainShellPage(initialIndex: initialIndex);
    },
    profile: (context) => const ProfilePage(),
    editProfile: (context) => const EditProfilePage(),
    changePassword: (context) => const ChangePasswordPage(),
    notifications: (context) => const NotificationsPage(),
    notificationSettings: (context) => const NotificationSettingsPage(),
    budgets: (context) => const BudgetsPage(),
    manageWallets: (context) => const ManageWalletsPage(),
    manageCategories: (context) => const ManageCategoriesPage(),
    reports: (context) => const ReportsScreen(),
  };
}
