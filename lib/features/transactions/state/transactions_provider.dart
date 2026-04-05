import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/connectivity_service.dart';
import '../../accounts/data/categories_repository.dart';
import '../data/transactions_repository.dart';
import '../models/transaction.dart';

final transactionsControllerProvider =
    AsyncNotifierProvider<TransactionsController, List<MoneyTransaction>>(
      TransactionsController.new,
    );

class TransactionsController extends AsyncNotifier<List<MoneyTransaction>> {
  @override
  Future<List<MoneyTransaction>> build() => _load(forceRefresh: true);

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(forceRefresh: true));
  }

  Future<List<MoneyTransaction>> _load({required bool forceRefresh}) async {
    try {
      await Future.wait([
        TransactionsRepository.instance.loadTransactions(forceRefresh: forceRefresh),
        CategoriesRepository.instance.loadCategories(forceRefresh: forceRefresh),
      ]);
      return List<MoneyTransaction>.unmodifiable(
        TransactionsRepository.instance.transactions,
      );
    } catch (_) {
      if (!await ConnectivityService.hasConnection()) {
        throw const OfflineException();
      }
      rethrow;
    }
  }
}
