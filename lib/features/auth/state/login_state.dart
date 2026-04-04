import 'package:flutter_riverpod/flutter_riverpod.dart';

final loginObscureProvider = StateProvider.autoDispose<bool>((ref) => true);
final loginLoadingProvider = StateProvider.autoDispose<bool>((ref) => false);
final loginErrorProvider = StateProvider.autoDispose<String?>((ref) => null);
