import 'package:flutter_riverpod/flutter_riverpod.dart';

final isRegisterModeProvider = StateProvider.autoDispose<bool>((ref) => false);
final loginObscureProvider = StateProvider.autoDispose<bool>((ref) => true);
final loginLoadingProvider = StateProvider.autoDispose<bool>((ref) => false);
final loginErrorProvider = StateProvider.autoDispose<String?>((ref) => null);

// Controls whether to show the "quick login" screen (saved session) or full login
final isQuickLoginModeProvider = StateProvider<bool>((ref) => false);
