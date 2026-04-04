import 'package:flutter_riverpod/flutter_riverpod.dart';

final changePasswordSavingProvider =
    StateProvider.autoDispose<bool>((ref) => false);
final changePasswordObscureOldProvider =
    StateProvider.autoDispose<bool>((ref) => true);
final changePasswordObscureNewProvider =
    StateProvider.autoDispose<bool>((ref) => true);
final changePasswordObscureConfirmProvider =
    StateProvider.autoDispose<bool>((ref) => true);
