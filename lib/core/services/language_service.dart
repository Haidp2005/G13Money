import 'package:flutter/foundation.dart';

enum AppLanguage { vietnamese, english }

class LanguageService {
  static final ValueNotifier<AppLanguage> notifier =
      ValueNotifier(AppLanguage.vietnamese);

  static AppLanguage get current => notifier.value;

  static bool get isVietnamese => current == AppLanguage.vietnamese;

  static void setLanguage(AppLanguage language) {
    if (notifier.value != language) {
      notifier.value = language;
    }
  }

  static String tr({required String vi, required String en}) {
    return isVietnamese ? vi : en;
  }

  static String get currentLanguageLabel => tr(vi: 'Tiếng Việt', en: 'English');
}
