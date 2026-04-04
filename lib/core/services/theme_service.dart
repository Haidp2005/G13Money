import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController() : super(ThemeMode.light);

  ThemeMode get currentMode => state;

  void setThemeMode(ThemeMode mode) {
    if (state != mode) {
      state = mode;
    }
  }
}

class ThemeService {
  static final ThemeModeController controller = ThemeModeController();

  static ThemeMode get currentMode => controller.currentMode;

  static bool get isDarkMode => currentMode == ThemeMode.dark;

  static void setThemeMode(ThemeMode mode) {
    controller.setThemeMode(mode);
  }
}
