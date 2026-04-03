import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/auth_service.dart';
import '../models/category_item.dart';

class CategoriesRepository {
  CategoriesRepository._();

  static final CategoriesRepository instance = CategoriesRepository._();

  final List<CategoryItem> _categories = [];
  bool _hasLoaded = false;
  String? _loadedUid;

  List<CategoryItem> get categories => List.unmodifiable(_categories);

  List<CategoryItem> categoriesByTypes(Set<String> types) {
    final allowed = types.map((e) => e.trim().toLowerCase()).toSet();
    return _categories
        .where((item) => allowed.contains(item.type.trim().toLowerCase()))
        .toList(growable: false);
  }

  bool existsCategoryForTypes(String categoryName, Set<String> types) {
    final normalizedName = categoryName.trim().toLowerCase();
    return categoriesByTypes(types)
        .any((item) => item.name.trim().toLowerCase() == normalizedName);
  }

  Future<List<CategoryItem>> loadCategories({bool forceRefresh = false}) async {
    final uid = AuthService.currentUserId;
    if (uid == null) {
      _categories.clear();
      _hasLoaded = false;
      _loadedUid = null;
      return categories;
    }

    if (!forceRefresh && _hasLoaded && _loadedUid == uid) {
      return categories;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('categories')
        .orderBy('createdAt', descending: true)
        .get();

    _categories
      ..clear()
      ..addAll(snapshot.docs.map((doc) => _fromFirestore(doc.id, doc.data())));

    _hasLoaded = true;
    _loadedUid = uid;
    return categories;
  }

  Future<CategoryItem> upsertCategory(CategoryItem category) async {
    final uid = AuthService.currentUserId;
    if (uid == null) {
      throw Exception('Ban chua dang nhap');
    }

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('categories')
        .doc(category.id);

    await docRef.set({
      'name': category.name,
      'type': category.type,
      'iconKey': category.iconKey,
      'colorHex': category.colorHex,
      'isDefault': category.isDefault,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final index = _categories.indexWhere((item) => item.id == category.id);
    if (index >= 0) {
      _categories[index] = category;
    } else {
      _categories.insert(0, category);
    }

    _hasLoaded = true;
    _loadedUid = uid;
    return category;
  }

  Future<void> deleteCategory(String categoryId) async {
    final uid = AuthService.currentUserId;
    if (uid == null) {
      throw Exception('Ban chua dang nhap');
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('categories')
        .doc(categoryId)
        .delete();

    _categories.removeWhere((item) => item.id == categoryId);
  }

  CategoryItem _fromFirestore(String id, Map<String, dynamic> data) {
    return CategoryItem(
      id: id,
      name: (data['name'] as String?) ?? '',
      type: (data['type'] as String?) ?? 'expense',
      iconKey: (data['iconKey'] as String?) ?? 'category',
      colorHex: (data['colorHex'] as String?) ?? '#0D7377',
      isDefault: (data['isDefault'] as bool?) ?? false,
    );
  }
}
