import 'package:flutter/material.dart';

import '../features/auth/ui/login_page.dart';
import '../features/overview/ui/overview_page.dart';

abstract final class AppRoutes {
	static const String login = '/login';
	static const String home = '/home';

	static final Map<String, WidgetBuilder> map = {
		login: (context) => const LoginPage(),
		home: (context) => const OverviewPage(),
	};
}
