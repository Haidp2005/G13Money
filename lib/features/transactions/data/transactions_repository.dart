import 'package:cloud_firestore/cloud_firestore.dart';

import '../../accounts/data/accounts_repository.dart';
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

  Future<List<MoneyTransaction>> loadTransactions() async {
    final uid = AuthService.currentUserId;
    if (uid == null) {
      _transactions.clear();
      _hasLoaded = false;
      _loadedUid = null;
      return transactions;
    }

    if (_hasLoaded && _loadedUid == uid) {
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

    await docRef.set(transaction.toFirestore());
    await legacyCollection.doc(docRef.id).set(transaction.toFirestore());

    _transactions.insert(0, transaction);
    _hasLoaded = true;
    _loadedUid = uid;
    return transaction;
  }
}
