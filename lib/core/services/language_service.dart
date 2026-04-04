import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLanguage { vietnamese, english }

class AppLanguageController extends StateNotifier<AppLanguage> {
  AppLanguageController() : super(AppLanguage.vietnamese);

  AppLanguage get current => state;

  void setLanguage(AppLanguage language) {
    if (state != language) {
      state = language;
    }
  }
}

class LanguageService {
  static final AppLanguageController controller = AppLanguageController();

  static AppLanguage get current => controller.current;

  static bool get isVietnamese => current == AppLanguage.vietnamese;

  static void setLanguage(AppLanguage language) {
    controller.setLanguage(language);
  }

  static String tr({required String vi, required String en}) {
    return isVietnamese ? vi : en;
  }

  static String get currentLanguageLabel => tr(vi: 'Tiếng Việt', en: 'English');
}
