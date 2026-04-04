import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/state/app_settings_providers.dart';
import '../core/services/language_service.dart';
import 'routes.dart';

class ExpenseManagerApp extends ConsumerWidget {
  const ExpenseManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appLanguageProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'G13 Money',
      debugShowCheckedModeBanner: false,
      locale: Locale(language == AppLanguage.vietnamese ? 'vi' : 'en'),
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D7377),
          secondary: const Color(0xFF6C63FF),
          tertiary: const Color(0xFF14A085),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D7377),
          secondary: const Color(0xFF6C63FF),
          tertiary: const Color(0xFF14A085),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.map,
    );
  }
}
