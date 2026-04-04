import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/language_service.dart';
import '../services/theme_service.dart';

final appLanguageProvider =
    StateNotifierProvider<AppLanguageController, AppLanguage>(
      (ref) => LanguageService.controller,
    );

final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) => ThemeService.controller,
);
