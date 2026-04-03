import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ThemeService {
  static final ValueNotifier<ThemeMode> notifier =
      ValueNotifier(ThemeMode.light);

  static ThemeMode get currentMode => notifier.value;

  static bool get isDarkMode => currentMode == ThemeMode.dark;

  static void setThemeMode(ThemeMode mode) {
    if (notifier.value != mode) {
      notifier.value = mode;
    }
  }
}
