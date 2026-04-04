import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/categories_repository.dart';
import '../models/category_item.dart';

final categoriesProvider =
    AsyncNotifierProvider<CategoriesController, List<CategoryItem>>(
      CategoriesController.new,
    );

final categoryFormTypeProvider = StateProvider.autoDispose<String>(
  (ref) => 'expense',
);
final categoryFormIconProvider = StateProvider.autoDispose<String>(
  (ref) => 'category',
);

class CategoriesController extends AsyncNotifier<List<CategoryItem>> {
  @override
  Future<List<CategoryItem>> build() => _load();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> upsert(CategoryItem item) async {
    await CategoriesRepository.instance.upsertCategory(item);
    await refresh();
  }

  Future<void> delete(String id) async {
    await CategoriesRepository.instance.deleteCategory(id);
    await refresh();
  }

  Future<List<CategoryItem>> _load() async {
    final data = await CategoriesRepository.instance.loadCategories();
    return List<CategoryItem>.unmodifiable(data);
  }
}
