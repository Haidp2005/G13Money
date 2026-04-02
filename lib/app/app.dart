import 'package:flutter/material.dart';

import 'routes.dart';

class ExpenseManagerApp extends StatelessWidget {
	const ExpenseManagerApp({super.key});

	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			title: 'G13 Money',
			debugShowCheckedModeBanner: false,
			theme: ThemeData(
				colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
				useMaterial3: true,
			),
			initialRoute: AppRoutes.transactionHistory,
			routes: AppRoutes.map,
		);
	}
}

class HomePlaceholderPage extends StatelessWidget {
	const HomePlaceholderPage({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Trang chinh')),
			body: const Center(
				child: Text('Man hinh chinh tam thoi (sau dang nhap)'),
			),
		);
	}
}
