import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/language_service.dart';
import '../data/accounts_repository.dart';
import '../data/categories_repository.dart';

final bankNotificationsProvider =
    AsyncNotifierProvider<BankNotificationsController, NotificationsViewData>(
      BankNotificationsController.new,
    );

class BankNotificationsController extends AsyncNotifier<NotificationsViewData> {
  @override
  Future<NotificationsViewData> build() => _load();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> markReviewed(BankReviewTransaction item) async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    final db = FirebaseFirestore.instance;
    final batch = db.batch();

    final txDocNew = db.collection('users').doc(uid).collection('GiaoDich').doc(item.id);
    final txDocLegacy = db.collection('users').doc(uid).collection('transactions').doc(item.id);

    batch.set(txDocNew, {
      'reviewNeeded': false,
      'reviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(txDocLegacy, {
      'reviewNeeded': false,
      'reviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (item.notificationId.trim().isNotEmpty) {
      final notiDoc = db.collection('users').doc(uid).collection('notifications').doc(item.notificationId);
      batch.set(
        notiDoc,
        {
          'isRead': true,
          'reviewStatus': 'done',
          'body': LanguageService.tr(
            vi: 'Da cap nhat giao dich ngan hang',
            en: 'Bank transaction has been updated',
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
    await refresh();
  }

  Future<NotificationsViewData> _load() async {
    final uid = AuthService.currentUserId;
    if (uid == null) {
      throw Exception(
        LanguageService.tr(vi: 'Ban chua dang nhap', en: 'You are not logged in'),
      );
    }

    await Future.wait([
      AccountsRepository.instance.loadAccounts(forceRefresh: true),
      CategoriesRepository.instance.loadCategories(forceRefresh: true),
    ]);

    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('GiaoDich')
          .where('source.provider', isEqualTo: 'sepay')
          .orderBy('date', descending: true)
          .get();
    } on FirebaseException {
      snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('GiaoDich')
          .get();
    }

    final allBankItems = snapshot.docs
        .map((doc) => BankReviewTransaction.fromFirestore(doc.id, doc.data()))
        .where((item) => item.sourceProvider == 'sepay')
        .toList(growable: false)
      ..sort((a, b) => b.date.compareTo(a.date));

    return NotificationsViewData(
      needReviewItems: List<BankReviewTransaction>.unmodifiable(
        allBankItems.where((item) => item.reviewNeeded),
      ),
      reviewedItems: List<BankReviewTransaction>.unmodifiable(
        allBankItems.where((item) => !item.reviewNeeded).take(20),
      ),
    );
  }
}

class NotificationsViewData {
  final List<BankReviewTransaction> needReviewItems;
  final List<BankReviewTransaction> reviewedItems;

  const NotificationsViewData({
    required this.needReviewItems,
    required this.reviewedItems,
  });
}

class BankReviewTransaction {
  final String id;
  final String title;
  final String note;
  final double amount;
  final String categoryName;
  final String walletName;
  final DateTime date;
  final bool reviewNeeded;
  final bool isIncome;
  final String sourceProvider;
  final String notificationId;

  const BankReviewTransaction({
    required this.id,
    required this.title,
    required this.note,
    required this.amount,
    required this.categoryName,
    required this.walletName,
    required this.date,
    required this.reviewNeeded,
    required this.isIncome,
    required this.sourceProvider,
    required this.notificationId,
  });

  factory BankReviewTransaction.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final rawDate = data['date'];
    DateTime dateValue;
    if (rawDate is Timestamp) {
      dateValue = rawDate.toDate();
    } else if (rawDate is DateTime) {
      dateValue = rawDate;
    } else {
      dateValue = DateTime.now();
    }

    final source = (data['source'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    final sourceTransferType = (source['transferType'] as String?)?.trim().toLowerCase() ?? '';
    final inferredIsIncome = sourceTransferType == 'out' || sourceTransferType == 'debit'
        ? false
        : ((data['isIncome'] as bool?) ?? true);

    return BankReviewTransaction(
      id: id,
      title: (data['title'] as String?) ?? '',
      note: (data['note'] as String?) ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      categoryName: (data['categoryName'] as String?) ?? '',
      walletName: (data['walletName'] as String?) ?? '',
      date: dateValue,
      reviewNeeded: (data['reviewNeeded'] as bool?) ?? ((data['categoryName'] as String?) ?? '').trim().isEmpty,
      isIncome: inferredIsIncome,
      sourceProvider: (source['provider'] as String?) ?? '',
      notificationId: (data['notificationId'] as String?) ?? '',
    );
  }
}
