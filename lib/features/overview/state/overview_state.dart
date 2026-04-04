import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accounts/models/account.dart';
import '../../transactions/models/transaction.dart';

final overviewSelectedPeriodProvider =
    StateProvider.autoDispose<int>((ref) => 1);
final overviewLoadingProvider = StateProvider.autoDispose<bool>((ref) => true);
final overviewErrorProvider = StateProvider.autoDispose<String?>((ref) => null);
final overviewWalletsProvider =
    StateProvider.autoDispose<List<Account>>((ref) => const <Account>[]);
final overviewTransactionsProvider =
    StateProvider.autoDispose<List<MoneyTransaction>>(
      (ref) => const <MoneyTransaction>[],
    );
