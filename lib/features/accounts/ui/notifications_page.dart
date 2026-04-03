import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/language_service.dart';
import '../../accounts/data/accounts_repository.dart';
import '../../accounts/data/categories_repository.dart';
import '../../transactions/ui/add_transaction_form_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final List<_BankReviewTransaction> _needReviewItems = [];
  final List<_BankReviewTransaction> _reviewedItems = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final uid = AuthService.currentUserId;
    if (uid == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = LanguageService.tr(vi: 'Ban chua dang nhap', en: 'You are not logged in');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
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
          .map((doc) => _BankReviewTransaction.fromFirestore(doc.id, doc.data()))
          .where((item) => item.sourceProvider == 'sepay')
          .toList(growable: false)
        ..sort((a, b) => b.date.compareTo(a.date));

      if (!mounted) return;
      setState(() {
        _needReviewItems
          ..clear()
          ..addAll(allBankItems.where((item) => item.reviewNeeded));
        _reviewedItems
          ..clear()
          ..addAll(allBankItems.where((item) => !item.reviewNeeded).take(20));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _openReview(_BankReviewTransaction item) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionFormPage(
          initialData: TransactionFormInitialData(
            transactionId: item.id,
            note: item.note.isEmpty ? item.title : item.note,
            walletName: item.walletName,
            category: item.categoryName,
            amount: item.amount,
            date: item.date,
            isIncome: item.isIncome,
          ),
        ),
      ),
    );

    if (updated == true) {
      await _markReviewed(item);
      await _loadItems();
    }
  }

  Future<void> _markReviewed(_BankReviewTransaction item) async {
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
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(LanguageService.tr(vi: 'Thong bao giao dich', en: 'Transaction notifications')),
        actions: [
          IconButton(
            tooltip: LanguageService.tr(vi: 'Tai lai', en: 'Refresh'),
            onPressed: _loadItems,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 38),
                        const SizedBox(height: 8),
                        Text(_loadError!, textAlign: TextAlign.center),
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: _loadItems,
                          child: Text(LanguageService.tr(vi: 'Thu lai', en: 'Retry')),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    Text(
                      LanguageService.tr(
                        vi: 'Can bo sung danh muc',
                        en: 'Need category update',
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_needReviewItems.isEmpty)
                      _emptyCard(
                        context,
                        LanguageService.tr(
                          vi: 'Khong co giao dich can cap nhat',
                          en: 'No bank transactions need updates',
                        ),
                      )
                    else
                      ..._needReviewItems.map((item) => _reviewTile(context, item)),
                    const SizedBox(height: 18),
                    Text(
                      LanguageService.tr(
                        vi: 'Da cap nhat gan day',
                        en: 'Recently updated',
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_reviewedItems.isEmpty)
                      _emptyCard(
                        context,
                        LanguageService.tr(
                          vi: 'Chua co giao dich da cap nhat',
                          en: 'No reviewed bank transactions yet',
                        ),
                      )
                    else
                      ..._reviewedItems.map((item) => _doneTile(context, item)),
                  ],
                ),
    );
  }

  Widget _emptyCard(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(color: scheme.outline)),
    );
  }

  Widget _reviewTile(BuildContext context, _BankReviewTransaction item) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.notifications_active_outlined),
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${LanguageService.tr(vi: 'So tien', en: 'Amount')}: ${_money(item.amount)}\n'
          '${LanguageService.tr(vi: 'Danh muc', en: 'Category')}: '
          '${item.categoryName.trim().isEmpty ? LanguageService.tr(vi: 'Chua co', en: 'Missing') : item.categoryName}',
        ),
        isThreeLine: true,
        trailing: FilledButton(
          onPressed: () => _openReview(item),
          child: Text(LanguageService.tr(vi: 'Sua', en: 'Edit')),
        ),
      ),
    );
  }

  Widget _doneTile(BuildContext context, _BankReviewTransaction item) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.check_circle_outline, color: Colors.green),
        title: Text(item.title),
        subtitle: Text(
          '${LanguageService.tr(vi: 'So tien', en: 'Amount')}: ${_money(item.amount)}\n'
          '${LanguageService.tr(vi: 'Danh muc', en: 'Category')}: ${item.categoryName}',
        ),
        isThreeLine: true,
      ),
    );
  }

  String _money(double amount) {
    final raw = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(raw[i]);
    }
    return '${buffer.toString()} đ';
  }
}

class _BankReviewTransaction {
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

  const _BankReviewTransaction({
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

  factory _BankReviewTransaction.fromFirestore(String id, Map<String, dynamic> data) {
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

    return _BankReviewTransaction(
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

