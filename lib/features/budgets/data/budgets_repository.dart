import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';
import '../../accounts/data/accounts_repository.dart';
import '../../accounts/data/categories_repository.dart';
import '../../shared/widgets/category_helper.dart';
import '../models/budget.dart';

class BudgetsRepository {
  BudgetsRepository._();

  static final BudgetsRepository instance = BudgetsRepository._();

  final List<Budget> _budgets = [];
  bool _hasLoaded = false;
  String? _loadedUid;

  List<Budget> get budgets => List.unmodifiable(_budgets);

  Future<List<Budget>> loadBudgets() async {
    final uid = AuthService.currentUserId;
    if (uid == null) {
      _budgets.clear();
      _hasLoaded = false;
      _loadedUid = null;
      return budgets;
    }

    if (_hasLoaded && _loadedUid == uid) {
      return budgets;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .orderBy('createdAt', descending: true)
        .get();

    _budgets
      ..clear()
      ..addAll(
        snapshot.docs.map((doc) => _fromFirestore(doc.id, doc.data())),
      );

    _hasLoaded = true;
    _loadedUid = uid;
    return budgets;
  }

  Future<Budget> upsertBudget(Budget budget) async {
    final uid = AuthService.currentUserId;
    if (uid == null) {
      throw Exception('Ban chua dang nhap');
    }

    await CategoriesRepository.instance.loadCategories(forceRefresh: true);
    await AccountsRepository.instance.loadAccounts(forceRefresh: true);

    if (!CategoriesRepository.instance
        .existsCategoryForTypes(budget.category, const <String>{'expense'})) {
      throw Exception('Ngan sach chi duoc su dung danh muc thuoc loai chi tieu');
    }

    final wallet = budget.walletName.trim().toLowerCase();
    final isAllWallets = wallet == 'tất cả ví' || wallet == 'tat ca vi' || wallet == 'all';
    if (!isAllWallets && !AccountsRepository.instance.existsWalletName(budget.walletName)) {
      throw Exception('Vi/tai khoan khong ton tai trong tai khoan hien tai');
    }

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .doc(budget.id);

    await docRef.set(_toFirestore(budget), SetOptions(merge: true));

    final index = _budgets.indexWhere((item) => item.id == budget.id);
    if (index >= 0) {
      _budgets[index] = budget;
    } else {
      _budgets.insert(0, budget);
    }

    _hasLoaded = true;
    _loadedUid = uid;
    return budget;
  }

  Future<void> deleteBudget(String budgetId) async {
    final uid = AuthService.currentUserId;
    if (uid == null) {
      throw Exception('Ban chua dang nhap');
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .doc(budgetId)
        .delete();

    _budgets.removeWhere((item) => item.id == budgetId);
  }

  Map<String, dynamic> _toFirestore(Budget budget) {
    final periodKey =
        '${budget.startDate.year}-${budget.startDate.month.toString().padLeft(2, '0')}';
    return {
      'title': budget.title,
      'categoryName': budget.category,
      'walletName': budget.walletName,
      'limit': budget.limit,
      'spent': budget.spent,
      'startDate': Timestamp.fromDate(budget.startDate),
      'endDate': Timestamp.fromDate(budget.endDate),
      'periodKey': periodKey,
      'colorHex': _toHex(budget.color),
      'iconKey': budget.icon.codePoint.toString(),
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Budget _fromFirestore(String id, Map<String, dynamic> data) {
    final category = (data['categoryName'] as String?) ?? '';
    final walletName = (data['walletName'] as String?) ?? 'Tat ca vi';

    return Budget(
      id: id,
      title: (data['title'] as String?) ?? '',
      category: category,
      walletName: walletName,
      limit: (data['limit'] as num?)?.toDouble() ?? 0,
      spent: (data['spent'] as num?)?.toDouble() ?? 0,
      startDate: _asDateTime(data['startDate']) ?? DateTime.now(),
      endDate: _asDateTime(data['endDate']) ?? DateTime.now(),
      color: _parseColor(
        (data['colorHex'] as String?) ?? '',
        fallback: CategoryHelper.colorFor(category),
      ),
      icon: _parseIcon((data['iconKey'] as String?) ?? '', category),
    );
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

  Color _parseColor(String value, {required Color fallback}) {
    final normalized = value.trim();
    if (normalized.isEmpty || !normalized.startsWith('#')) {
      return fallback;
    }

    final hex = normalized.substring(1);
    if (hex.length != 6 && hex.length != 8) {
      return fallback;
    }

    final argbHex = hex.length == 6 ? 'FF$hex' : hex;
    final parsed = int.tryParse(argbHex, radix: 16);
    if (parsed == null) {
      return fallback;
    }
    return Color(parsed);
  }

  IconData _parseIcon(String value, String category) {
    final _ = value;
    return CategoryHelper.iconFor(category);
  }

  String _toHex(Color color) {
    final red = (color.r * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    final green = (color.g * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    final blue = (color.b * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    return '#$red$green$blue'.toUpperCase();
  }
}
