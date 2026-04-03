import 'package:cloud_firestore/cloud_firestore.dart';

import '../../accounts/data/accounts_repository.dart';
import '../../accounts/models/account.dart';
import '../../accounts/data/categories_repository.dart';
import '../../../core/services/auth_service.dart';
import '../models/transaction.dart';

class TransactionsRepository {
  TransactionsRepository._();

  static final TransactionsRepository instance = TransactionsRepository._();
  static const String _transactionCollection = 'GiaoDich';
  static const String _legacyTransactionCollection = 'transactions';

  final List<MoneyTransaction> _transactions = [];
  bool _hasLoaded = false;
  String? _loadedUid;

  List<MoneyTransaction> get transactions => List.unmodifiable(_transactions);

  String _normalizeWalletName(String value) => value.trim().toLowerCase();

  double _signedAmount({required bool isIncome, required double amount}) {
    return isIncome ? amount.abs() : -amount.abs();
  }

  Account _findWalletAccountOrThrow(String walletName) {
    final normalized = _normalizeWalletName(walletName);
    final account = AccountsRepository.instance.accounts
        .where((item) => _normalizeWalletName(item.name) == normalized)
        .cast<Account?>()
        .firstWhere(
          (item) => item != null,
          orElse: () => null,
        );

    if (account == null) {
      throw Exception('Ví/tài khoản không tồn tại trong tài khoản hiện tại');
    }
    return account;
  }

  Future<List<MoneyTransaction>> loadTransactions({bool forceRefresh = false}) async {
    final uid = AuthService.currentUserId;
    if (uid == null) {
      _transactions.clear();
      _hasLoaded = false;
      _loadedUid = null;
      return transactions;
    }

    if (!forceRefresh && _hasLoaded && _loadedUid == uid) {
      return transactions;
    }

    final primarySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(_transactionCollection)
        .orderBy('date', descending: true)
        .get();

    final legacySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(_legacyTransactionCollection)
        .orderBy('date', descending: true)
        .get();

    final byId = <String, MoneyTransaction>{};
    for (final doc in primarySnapshot.docs) {
      byId[doc.id] = MoneyTransaction.fromFirestore(doc.id, doc.data());
    }
    for (final doc in legacySnapshot.docs) {
      byId.putIfAbsent(doc.id, () => MoneyTransaction.fromFirestore(doc.id, doc.data()));
    }

    final merged = byId.values.toList(growable: false)
      ..sort((a, b) => b.date.compareTo(a.date));

    _transactions
      ..clear()
      ..addAll(merged);
    _hasLoaded = true;
    _loadedUid = uid;

    return transactions;
  }

  Future<MoneyTransaction> addTransaction({
    required String title,
    required String category,
    required String walletName,
    required double amount,
    required DateTime date,
    required bool isIncome,
  }) async {
    final uid = AuthService.currentUserId;
    if (uid == null) {
      throw Exception('Bạn chưa đăng nhập');
    }

    await CategoriesRepository.instance.loadCategories(forceRefresh: true);
    await AccountsRepository.instance.loadAccounts(forceRefresh: true);

    final allowedTypes = isIncome
        ? <String>{'income'}
        : <String>{'expense', 'debt'};

    if (!CategoriesRepository.instance.existsCategoryForTypes(category, allowedTypes)) {
      throw Exception('Danh mục không hợp lệ cho loại giao dịch này');
    }

    if (!AccountsRepository.instance.existsWalletName(walletName)) {
      throw Exception('Ví/tài khoản không tồn tại trong tài khoản hiện tại');
    }

    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(_transactionCollection);

    final legacyCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(_legacyTransactionCollection);

    final docRef = collection.doc();
    final transaction = MoneyTransaction(
      id: docRef.id,
      title: title,
      category: category,
      walletName: walletName,
      amount: amount,
      date: date,
      isIncome: isIncome,
    );

    final walletAccount = _findWalletAccountOrThrow(walletName);
    final walletDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('accounts')
        .doc(walletAccount.id);

    final delta = _signedAmount(isIncome: isIncome, amount: amount);
    final nextBalance = walletAccount.balance + delta;

    final batch = FirebaseFirestore.instance.batch();
    batch.set(docRef, transaction.toFirestore(), SetOptions(merge: true));
    batch.set(legacyCollection.doc(docRef.id), transaction.toFirestore(), SetOptions(merge: true));
    batch.set(
      walletDoc,
      {
        'balance': nextBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();

    await AccountsRepository.instance.loadAccounts(forceRefresh: true);

    _transactions.insert(0, transaction);
    _hasLoaded = true;
    _loadedUid = uid;
    return transaction;
  }

  Future<MoneyTransaction> updateTransaction({
    required String id,
    required String title,
    required String category,
    required String walletName,
    required double amount,
    required DateTime date,
    required bool isIncome,
  }) async {
    final uid = AuthService.currentUserId;
    if (uid == null) {
      throw Exception('Bạn chưa đăng nhập');
    }

    await CategoriesRepository.instance.loadCategories(forceRefresh: true);
    await AccountsRepository.instance.loadAccounts(forceRefresh: true);

    final allowedTypes = isIncome
        ? <String>{'income'}
        : <String>{'expense', 'debt'};

    if (!CategoriesRepository.instance.existsCategoryForTypes(category, allowedTypes)) {
      throw Exception('Danh mục không hợp lệ cho loại giao dịch này');
    }

    if (!AccountsRepository.instance.existsWalletName(walletName)) {
      throw Exception('Ví/tài khoản không tồn tại trong tài khoản hiện tại');
    }

    final transaction = MoneyTransaction(
      id: id,
      title: title,
      category: category,
      walletName: walletName,
      amount: amount,
      date: date,
      isIncome: isIncome,
    );

    final primaryDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(_transactionCollection)
        .doc(id);

    final legacyDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(_legacyTransactionCollection)
        .doc(id);

    final primarySnapshot = await primaryDoc.get();
    Map<String, dynamic>? oldData = primarySnapshot.data();
    if (oldData == null) {
      final legacySnapshot = await legacyDoc.get();
      oldData = legacySnapshot.data();
    }
    if (oldData == null) {
      throw Exception('Không tìm thấy giao dịch để cập nhật');
    }

    final oldTx = MoneyTransaction.fromFirestore(id, oldData);

    final newWallet = _findWalletAccountOrThrow(walletName);
    final oldWallet = _findWalletAccountOrThrow(oldTx.walletName);

    final oldEffect = _signedAmount(isIncome: oldTx.isIncome, amount: oldTx.amount);
    final newEffect = _signedAmount(isIncome: isIncome, amount: amount);

    final batch = FirebaseFirestore.instance.batch();
    batch.set(primaryDoc, transaction.toFirestore(), SetOptions(merge: true));
    batch.set(legacyDoc, transaction.toFirestore(), SetOptions(merge: true));

    final accountsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('accounts');

    if (oldWallet.id == newWallet.id) {
      final updatedBalance = oldWallet.balance - oldEffect + newEffect;
      batch.set(
        accountsCollection.doc(oldWallet.id),
        {
          'balance': updatedBalance,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } else {
      final oldWalletBalance = oldWallet.balance - oldEffect;
      final newWalletBalance = newWallet.balance + newEffect;

      batch.set(
        accountsCollection.doc(oldWallet.id),
        {
          'balance': oldWalletBalance,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      batch.set(
        accountsCollection.doc(newWallet.id),
        {
          'balance': newWalletBalance,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
    await AccountsRepository.instance.loadAccounts(forceRefresh: true);

    final existingIndex = _transactions.indexWhere((item) => item.id == id);
    if (existingIndex >= 0) {
      _transactions[existingIndex] = transaction;
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    }

    _hasLoaded = true;
    _loadedUid = uid;
    return transaction;
  }
}
