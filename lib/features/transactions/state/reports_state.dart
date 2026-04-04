import 'package:flutter_riverpod/flutter_riverpod.dart';

final reportsTouchedIncomeIndexProvider =
    StateProvider.autoDispose<int>((ref) => -1);
final reportsTouchedExpenseIndexProvider =
    StateProvider.autoDispose<int>((ref) => -1);
final reportsReloadTickProvider = StateProvider.autoDispose<int>((ref) => 0);
