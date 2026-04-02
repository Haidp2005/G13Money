import 'package:flutter/material.dart';

import '../features/auth/ui/login_page.dart';
import '../features/transaction_history/screens/transaction_history_screen.dart';
import 'app.dart';

abstract final class AppRoutes {
	static const String login = '/login';
	static const String home = '/home';
	static const String transactionHistory = '/transaction-history';

	static final Map<String, WidgetBuilder> map = {
		login: (context) => const LoginPage(),
		home: (context) => const HomePlaceholderPage(),
		transactionHistory: (context) => const TransactionHistoryScreen(),
	};
}
