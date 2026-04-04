import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TransactionFormType { expense, income }

final transactionTypeProvider =
    StateProvider.autoDispose<TransactionFormType>(
      (ref) => TransactionFormType.expense,
    );
final transactionSelectedWalletProvider =
    StateProvider.autoDispose<String>((ref) => '');
final transactionSelectedCategoryProvider =
    StateProvider.autoDispose<String>((ref) => '');
final transactionSelectedDateProvider =
    StateProvider.autoDispose<DateTime>((ref) => DateTime.now());
final transactionAttachmentsProvider =
    StateProvider.autoDispose<List<Uint8List>>((ref) => const <Uint8List>[]);
final transactionSubmittingProvider =
    StateProvider.autoDispose<bool>((ref) => false);
final transactionMetaLoadingProvider =
    StateProvider.autoDispose<bool>((ref) => true);
