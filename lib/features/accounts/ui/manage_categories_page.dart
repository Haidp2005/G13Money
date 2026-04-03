import 'package:flutter/material.dart';

import '../../../core/services/language_service.dart';
import '../data/categories_repository.dart';
import '../models/category_item.dart';

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

class ManageCategoriesPage extends StatefulWidget {
  const ManageCategoriesPage({super.key});

  @override
  State<ManageCategoriesPage> createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  final List<CategoryItem> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final data = await CategoriesRepository.instance.loadCategories();
    if (!mounted) return;
    setState(() {
      _categories
        ..clear()
        ..addAll(data);
      _isLoading = false;
    });
  }

  Future<void> _openCategoryForm([CategoryItem? item]) async {
    final result = await showModalBottomSheet<CategoryItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategoryFormSheet(initial: item),
    );

    if (result == null || !mounted) return;

    await CategoriesRepository.instance.upsertCategory(result);
    if (!mounted) return;

    setState(() {
      final index = _categories.indexWhere((it) => it.id == result.id);
      if (index >= 0) {
        _categories[index] = result;
      } else {
        _categories.insert(0, result);
      }
    });
  }

  Future<void> _deleteCategory(CategoryItem item) async {
    await CategoriesRepository.instance.deleteCategory(item.id);
    if (!mounted) return;
    setState(() {
      _categories.removeWhere((it) => it.id == item.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final expenseItems = _categories
        .where((item) => item.type.trim().toLowerCase() == 'expense')
        .toList(growable: false);
    final incomeItems = _categories
        .where((item) => item.type.trim().toLowerCase() == 'income')
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(LanguageService.tr(vi: 'Danh mục', en: 'Categories')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCategoryForm(),
        icon: const Icon(Icons.add),
        label: Text(LanguageService.tr(vi: 'Thêm danh mục', en: 'Add category')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
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
                      items: incomeItems,
                      emptyText: LanguageService.tr(
                        vi: 'Chưa có danh mục thu',
                        en: 'No income categories',
                      ),
                    ),
                  ],
                ),
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
                            _openCategoryForm(item);
                          } else if (value == 'delete') {
                            _deleteCategory(item);
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

class _CategoryFormSheet extends StatefulWidget {
  final CategoryItem? initial;
  const _CategoryFormSheet({this.initial});

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  String _type = 'expense';
  String _iconKey = 'category';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial?.name ?? '');
    _type = widget.initial?.type ?? 'expense';
    _iconKey = widget.initial?.iconKey ?? 'category';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final model = CategoryItem(
      id: widget.initial?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      type: _type,
      iconKey: _iconKey,
      colorHex: widget.initial?.colorHex ?? '#0D7377',
      isDefault: false,
    );

    Navigator.pop(context, model);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                        selected: _type == 'expense',
                        onTap: () => setState(() => _type = 'expense'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TypeChip(
                        label: LanguageService.tr(vi: 'Thu', en: 'Income'),
                        selected: _type == 'income',
                        onTap: () => setState(() => _type = 'income'),
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
                    final selected = _iconKey == option.key;
                    return InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: () => setState(() => _iconKey = option.key),
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
  for (final option in _iconOptions) {
    if (option.key == key) return option.icon;
  }

  switch (key) {
    case 'car':
      return Icons.directions_car_outlined;
    case 'shopping':
      return Icons.shopping_bag_outlined;
    case 'salary':
      return Icons.payments_outlined;
    case 'bonus':
      return Icons.card_giftcard_outlined;
    case 'income_other':
      return Icons.moving_outlined;
  }

  return Icons.category_outlined;
}
