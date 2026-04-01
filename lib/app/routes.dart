import 'package:flutter/material.dart';

import '../features/auth/ui/login_page.dart';
import '../features/accounts/ui/accounts_page.dart';
import '../features/accounts/ui/edit_profile_page.dart';
import 'app.dart';

abstract final class AppRoutes {
  static const String login = '/login';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';

  static final Map<String, WidgetBuilder> map = {
    login: (context) => const LoginPage(),
    profile: (context) => const ProfilePage(),
    editProfile: (context) => const EditProfilePage(),
  };
}
