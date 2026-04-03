import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/services/language_service.dart';
import '../core/services/theme_service.dart';
import 'routes.dart';

class ExpenseManagerApp extends StatelessWidget {
  const ExpenseManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: LanguageService.notifier,
      builder: (context, _, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeService.notifier,
          builder: (context, themeMode, _) {
            return MaterialApp(
              title: 'G13 Money',
              debugShowCheckedModeBanner: false,
              locale: Locale(LanguageService.isVietnamese ? 'vi' : 'en'),
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
              initialRoute: AppRoutes.login,
              routes: AppRoutes.map,
            );
          },
        );
      },
    );
  }
}
