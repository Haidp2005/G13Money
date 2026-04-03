import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/auth_service.dart';
import '../models/account.dart';

class AccountsRepository {
  AccountsRepository._();

  static final AccountsRepository instance = AccountsRepository._();

  final List<Account> _accounts = [];
  bool _hasLoaded = false;
  String? _loadedUid;

  List<Account> get accounts => List.unmodifiable(_accounts);

  List<String> walletNames() {
    return _accounts.map((item) => item.name).toList(growable: false);
  }

  bool existsWalletName(String walletName) {
    final normalized = walletName.trim().toLowerCase();
    return _accounts.any((item) => item.name.trim().toLowerCase() == normalized);
  }

  Future<List<Account>> loadAccounts({bool forceRefresh = false}) async {
    final uid = AuthService.currentUserId;
    if (uid == null) {
      _accounts.clear();
      _hasLoaded = false;
      _loadedUid = null;
      return accounts;
    }

    if (!forceRefresh && _hasLoaded && _loadedUid == uid) {
      return accounts;
    }

    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('accounts')
          .where('isArchived', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();
    } on FirebaseException {
      // Fallback to a simpler query to avoid hard failures when indexes/fields are inconsistent.
      snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('accounts')
          .get();
    }

    _accounts
      ..clear()
      ..addAll(
        snapshot.docs
            .map((doc) => _fromFirestore(doc.id, doc.data()))
            .where((item) => !item.isArchived),
      );

    _accounts.sort((a, b) => b.id.compareTo(a.id));

    _hasLoaded = true;
    _loadedUid = uid;
    return accounts;
  }

  Future<Account> upsertAccount(Account account) async {
    final uid = AuthService.currentUserId;
    if (uid == null) {
      throw Exception('Ban chua dang nhap');
    }

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('accounts')
        .doc(account.id);

    await docRef.set({
      'name': account.name,
      'type': account.type,
      'balance': account.balance,
      'colorHex': account.colorHex,
      'isArchived': account.isArchived,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final index = _accounts.indexWhere((item) => item.id == account.id);
    if (index >= 0) {
      _accounts[index] = account;
    } else {
      _accounts.insert(0, account);
    }

    _hasLoaded = true;
    _loadedUid = uid;
    return account;
  }

  Future<void> deleteAccount(String accountId) async {
    final uid = AuthService.currentUserId;
    if (uid == null) {
      throw Exception('Ban chua dang nhap');
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('accounts')
        .doc(accountId)
        .set({
      'isArchived': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _accounts.removeWhere((item) => item.id == accountId);
  }

  Account _fromFirestore(String id, Map<String, dynamic> data) {
    return Account(
      id: id,
      name: (data['name'] as String?) ?? '',
      type: (data['type'] as String?) ?? 'cash',
      balance: (data['balance'] as num?)?.toDouble() ?? 0,
      colorHex: (data['colorHex'] as String?) ?? '#0D7377',
      isArchived: (data['isArchived'] as bool?) ?? false,
    );
  }
}
