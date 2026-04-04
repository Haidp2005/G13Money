import 'package:flutter_riverpod/flutter_riverpod.dart';

final budgetFormCategoryProvider =
    StateProvider.autoDispose<String>((ref) => '');
final budgetFormWalletProvider =
    StateProvider.autoDispose<String>((ref) => 'Tất cả ví');
final budgetFormLoadingChoicesProvider =
    StateProvider.autoDispose<bool>((ref) => true);
final budgetFormStartDateProvider =
    StateProvider.autoDispose<DateTime>((ref) => DateTime.now());
final budgetFormEndDateProvider =
    StateProvider.autoDispose<DateTime>((ref) => DateTime.now());
