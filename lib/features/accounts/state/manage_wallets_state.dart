import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/accounts_repository.dart';
import '../models/account.dart';

final walletsProvider = AsyncNotifierProvider<WalletsController, List<Account>>(
  WalletsController.new,
);

final accountFormTypeProvider = StateProvider.autoDispose<String>(
  (ref) => 'cash',
);

class WalletsController extends AsyncNotifier<List<Account>> {
  @override
  Future<List<Account>> build() => _load();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> upsert(Account account) async {
    await AccountsRepository.instance.upsertAccount(account);
    await refresh();
  }

  Future<void> delete(String accountId) async {
    await AccountsRepository.instance.deleteAccount(accountId);
    await refresh();
  }

  Future<List<Account>> _load() async {
    final data = await AccountsRepository.instance.loadAccounts(forceRefresh: true);
    return List<Account>.unmodifiable(data);
  }
}
