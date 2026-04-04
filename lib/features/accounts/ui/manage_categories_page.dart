import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/language_service.dart';
import '../../shared/widgets/category_helper.dart';
import '../models/category_item.dart';
import '../state/manage_categories_state.dart';

const List<_IconOption> _iconOptions = [
  _IconOption('category', Icons.category_outlined),
  _IconOption('restaurant', Icons.restaurant_outlined),
  _IconOption('directions_car', Icons.directions_car_outlined),
  _IconOption('shopping_bag', Icons.shopping_bag_outlined),
  _IconOption('home', Icons.home_outlined),
  _IconOption('health', Icons.favorite_outline),
  _IconOption('education', Icons.school_outlined),
  _IconOption('bill', Icons.receipt_long_outlined),
  _IconOption('payments', Icons.payments_outlined),
  _IconOption('card_giftcard', Icons.card_giftcard_outlined),
  _IconOption('trending_up', Icons.trending_up_outlined),
  _IconOption('moving', Icons.moving_outlined),
];

class ManageCategoriesPage extends ConsumerWidget {
  const ManageCategoriesPage({super.key});

  Future<void> _openCategoryForm(BuildContext context, WidgetRef ref, [CategoryItem? item]) async {
    final result = await showModalBottomSheet<CategoryItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategoryFormSheet(initial: item),
    );

    if (result == null || !context.mounted) return;
    await ref.read(categoriesProvider.notifier).upsert(result);
  }

  Future<void> _deleteCategory(WidgetRef ref, CategoryItem item) async {
    await ref.read(categoriesProvider.notifier).delete(item.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(categoriesProvider);

    return categoriesState.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: Text(LanguageService.tr(vi: 'Danh mục', en: 'Categories')),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(
          title: Text(LanguageService.tr(vi: 'Danh mục', en: 'Categories')),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => ref.read(categoriesProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh),
          label: Text(LanguageService.tr(vi: 'Thử lại', en: 'Retry')),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              error.toString().replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (categories) {
    final expenseItems = categories
        .where((item) => item.type.trim().toLowerCase() == 'expense')
        .toList(growable: false);
    final incomeItems = categories
        .where((item) => item.type.trim().toLowerCase() == 'income')
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(LanguageService.tr(vi: 'Danh mục', en: 'Categories')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCategoryForm(context, ref),
        icon: const Icon(Icons.add),
        label: Text(LanguageService.tr(vi: 'Thêm danh mục', en: 'Add category')),
      ),
      body: categories.isEmpty
              ? Center(
                  child: Text(
                    LanguageService.tr(
                      vi: 'Chưa có danh mục nào.',
                      en: 'No category yet.',
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    _sectionHeader(
                      context,
                      icon: Icons.arrow_downward_rounded,
                      label: LanguageService.tr(vi: 'Danh mục Chi', en: 'Expense categories'),
                      color: const Color(0xFFFF6B6B),
                    ),
                    const SizedBox(height: 10),
                    _sectionCard(
                      context,
                      ref: ref,
                      items: expenseItems,
                      emptyText: LanguageService.tr(
                        vi: 'Chưa có danh mục chi',
                        en: 'No expense categories',
                      ),
                    ),
                    const SizedBox(height: 18),
                    _sectionHeader(
                      context,
                      icon: Icons.arrow_upward_rounded,
                      label: LanguageService.tr(vi: 'Danh mục Thu', en: 'Income categories'),
                      color: const Color(0xFF2DCC5A),
                    ),
                    const SizedBox(height: 10),
                    _sectionCard(
                      context,
                      ref: ref,
                      items: incomeItems,
                      emptyText: LanguageService.tr(
                        vi: 'Chưa có danh mục thu',
                        en: 'No income categories',
                      ),
                    ),
                  ],
                ),
    );
      },
    );
  }

  Widget _sectionHeader(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required WidgetRef ref,
    required List<CategoryItem> items,
    required String emptyText,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: items.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(14),
              child: Text(emptyText, style: TextStyle(color: scheme.outline)),
            )
          : Column(
              children: items.asMap().entries.map((entry) {
                final item = entry.value;
                final isLast = entry.key == items.length - 1;
                return Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: scheme.primaryContainer,
                        child: Icon(_iconForKey(item.iconKey), color: scheme.primary),
                      ),
                      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(item.type),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _openCategoryForm(context, ref, item);
                          } else if (value == 'delete') {
                            _deleteCategory(ref, item);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(LanguageService.tr(vi: 'Sửa', en: 'Edit')),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(LanguageService.tr(vi: 'Xóa', en: 'Delete')),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        indent: 70,
                        color: scheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                  ],
                );
              }).toList(growable: false),
            ),
    );
  }
}

class _CategoryFormSheet extends ConsumerStatefulWidget {
  final CategoryItem? initial;
  const _CategoryFormSheet({this.initial});

  @override
  ConsumerState<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<_CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial?.name ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(categoryFormTypeProvider.notifier).state =
        widget.initial?.type ?? 'expense';
      ref.read(categoryFormIconProvider.notifier).state =
        widget.initial?.iconKey ?? 'category';
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final selectedType = ref.read(categoryFormTypeProvider);
    final selectedIcon = ref.read(categoryFormIconProvider);

    final model = CategoryItem(
      id: widget.initial?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      type: selectedType,
      iconKey: selectedIcon,
      colorHex: widget.initial?.colorHex ?? '#0D7377',
      isDefault: false,
    );

    Navigator.pop(context, model);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedType = ref.watch(categoryFormTypeProvider);
    final selectedIcon = ref.watch(categoryFormIconProvider);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.initial == null
                      ? LanguageService.tr(vi: 'Tạo danh mục mới', en: 'Create category')
                      : LanguageService.tr(vi: 'Chỉnh sửa danh mục', en: 'Edit category'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: LanguageService.tr(vi: 'Tên danh mục', en: 'Category name'),
                    prefixIcon: const Icon(Icons.edit_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? LanguageService.tr(vi: 'Vui lòng nhập tên', en: 'Please enter name')
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  LanguageService.tr(vi: 'Loại danh mục', en: 'Category type'),
                  style: TextStyle(color: scheme.outline),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _TypeChip(
                        label: LanguageService.tr(vi: 'Chi', en: 'Expense'),
                        selected: selectedType == 'expense',
                        onTap: () =>
                            ref.read(categoryFormTypeProvider.notifier).state = 'expense',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TypeChip(
                        label: LanguageService.tr(vi: 'Thu', en: 'Income'),
                        selected: selectedType == 'income',
                        onTap: () =>
                            ref.read(categoryFormTypeProvider.notifier).state = 'income',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  LanguageService.tr(vi: 'Chọn biểu tượng', en: 'Choose icon'),
                  style: TextStyle(color: scheme.outline),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _iconOptions.map((option) {
                    final selected = selectedIcon == option.key;
                    return InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: () =>
                          ref.read(categoryFormIconProvider.notifier).state = option.key,
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: selected
                            ? scheme.primary.withValues(alpha: 0.18)
                            : scheme.surfaceContainerHighest,
                        child: Icon(
                          option.icon,
                          color: selected ? scheme.primary : scheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }).toList(growable: false),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(LanguageService.tr(vi: 'Lưu danh mục', en: 'Save category')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.16)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? scheme.primary : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _IconOption {
  final String key;
  final IconData icon;

  const _IconOption(this.key, this.icon);
}

IconData _iconForKey(String key) {
  return CategoryHelper.iconForKey(key);
}
