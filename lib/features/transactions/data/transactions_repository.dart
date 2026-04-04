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

  DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  Future<Map<String, dynamic>> _loadPreferences(String uid) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('preferences')
        .get();

    return snapshot.data() ?? <String, dynamic>{};
  }

  Future<void> _createNewTransactionNotification({
    required String uid,
    required MoneyTransaction transaction,
    required bool enabled,
  }) async {
    if (!enabled) return;

    final notificationId = 'tx_${transaction.id}';
    final signedAmount =
        '${transaction.isIncome ? '+' : '-'}${transaction.amount.toStringAsFixed(0)} đ';
    final title = 'Có Giao dịch mới';
    final body = 'Có Giao dịch mới: $signedAmount';

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .set({
      'type': 'transaction_new',
      'title': title,
      'body': body,
      'isRead': false,
      'meta': {
        'transactionId': transaction.id,
        'walletName': transaction.walletName,
        'provider': 'manual',
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  bool _isAllWalletBudget(String walletName) {
    final normalizedWallet = walletName.trim().toLowerCase();
    return normalizedWallet == 'tất cả ví' ||
        normalizedWallet == 'tất cả loại ví' ||
        normalizedWallet == 'tat ca vi' ||
        normalizedWallet == 'all';
  }

  bool _matchesBudget(Map<String, dynamic> budget, MoneyTransaction tx) {
    if (tx.isIncome) return false;

    final categoryName = ((budget['categoryName'] as String?) ?? '').trim().toLowerCase();
    final walletName = ((budget['walletName'] as String?) ?? '').trim();
    final startDate = _asDateTime(budget['startDate']);
    final endDate = _asDateTime(budget['endDate']);

    if (categoryName.isEmpty || startDate == null || endDate == null) return false;
    if (tx.category.trim().toLowerCase() != categoryName) return false;
    if (tx.date.isBefore(startDate) || tx.date.isAfter(endDate)) return false;

    if (_isAllWalletBudget(walletName)) {
      return true;
    }

    return tx.walletName.trim().toLowerCase() == walletName.toLowerCase();
  }

  Future<void> _syncBudgetThresholdNotifications({
    required String uid,
    required List<MoneyTransaction> allTransactions,
    required bool budgetAlertsEnabled,
    required int thresholdPercent,
  }) async {
    if (!budgetAlertsEnabled) return;

    final budgetsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .get();

    for (final doc in budgetsSnapshot.docs) {
      final data = doc.data();
      final limit = (data['limit'] as num?)?.toDouble() ?? 0;
      if (limit <= 0) continue;

      final matchedSpent = allTransactions
          .where((tx) => _matchesBudget(data, tx))
          .fold<double>(0, (total, tx) => total + tx.amount);

      final usagePercent = (matchedSpent / limit) * 100;
      if (usagePercent < thresholdPercent) continue;

      final startDate = _asDateTime(data['startDate']);
      final periodKey = startDate == null
          ? DateTime.now().toIso8601String().substring(0, 7)
          : '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}';
      final notificationId = 'budget_threshold_${doc.id}_$periodKey';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .set({
        'type': 'budget_alert',
        'title': 'Đạt ngưỡng ngân sách',
        'body':
            'Ngân sách ${data['title'] ?? ''} đã dùng ${usagePercent.toStringAsFixed(0)}% (ngưỡng $thresholdPercent%)',
        'isRead': false,
        'meta': {
          'budgetId': doc.id,
          'thresholdPercent': thresholdPercent,
          'usagePercent': usagePercent,
          'periodKey': periodKey,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
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

    final prefs = await _loadPreferences(uid);
    final transactionAlertsEnabled =
        (prefs['transactionAlerts'] as bool?) ?? true;
    final budgetAlertsEnabled = (prefs['budgetAlerts'] as bool?) ?? true;
    final thresholdPercent =
        ((prefs['budgetAlertThresholdPercent'] as num?)?.toInt() ?? 80)
            .clamp(1, 100);

    await _createNewTransactionNotification(
      uid: uid,
      transaction: transaction,
      enabled: transactionAlertsEnabled,
    );

    final latestTransactions = await loadTransactions(forceRefresh: true);
    await _syncBudgetThresholdNotifications(
      uid: uid,
      allTransactions: latestTransactions,
      budgetAlertsEnabled: budgetAlertsEnabled,
      thresholdPercent: thresholdPercent,
    );

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

    final prefs = await _loadPreferences(uid);
    final budgetAlertsEnabled = (prefs['budgetAlerts'] as bool?) ?? true;
    final thresholdPercent =
        ((prefs['budgetAlertThresholdPercent'] as num?)?.toInt() ?? 80)
            .clamp(1, 100);

    final latestTransactions = await loadTransactions(forceRefresh: true);
    await _syncBudgetThresholdNotifications(
      uid: uid,
      allTransactions: latestTransactions,
      budgetAlertsEnabled: budgetAlertsEnabled,
      thresholdPercent: thresholdPercent,
    );

    final existingIndex = _transactions.indexWhere((item) => item.id == id);
    if (existingIndex >= 0) {
      _transactions[existingIndex] = transaction;
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    }

    _hasLoaded = true;
    _loadedUid = uid;
    return transaction;
  }

  Future<void> deleteTransaction(String id) async {
    final uid = AuthService.currentUserId;
    if (uid == null) {
      throw Exception('Bạn chưa đăng nhập');
    }

    await AccountsRepository.instance.loadAccounts(forceRefresh: true);

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
      throw Exception('Không tìm thấy giao dịch để xoá');
    }

    final oldTx = MoneyTransaction.fromFirestore(id, oldData);
    final wallet = _findWalletAccountOrThrow(oldTx.walletName);
    final oldEffect = _signedAmount(isIncome: oldTx.isIncome, amount: oldTx.amount);
    final updatedBalance = wallet.balance - oldEffect;

    final walletDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('accounts')
        .doc(wallet.id);

    final batch = FirebaseFirestore.instance.batch();
    batch.delete(primaryDoc);
    batch.delete(legacyDoc);
    batch.set(
      walletDoc,
      {
        'balance': updatedBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.delete(
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc('tx_$id'),
    );
    await batch.commit();

    await AccountsRepository.instance.loadAccounts(forceRefresh: true);

    _transactions.removeWhere((item) => item.id == id);
    _hasLoaded = true;
    _loadedUid = uid;
  }
}
