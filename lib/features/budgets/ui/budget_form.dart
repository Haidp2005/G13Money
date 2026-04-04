import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/language_service.dart';
import '../../accounts/data/accounts_repository.dart';
import '../../accounts/data/categories_repository.dart';
import '../../shared/widgets/category_helper.dart';
import '../models/budget.dart';
import '../state/budget_form_state.dart';


class BudgetForm extends ConsumerStatefulWidget {
  final Budget? initialBudget;

  const BudgetForm({super.key, this.initialBudget});

  @override
  ConsumerState<BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends ConsumerState<BudgetForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _limitController;

  final List<String> _categories = [];

  final List<String> _wallets = ['Tất cả ví'];

  @override
  void initState() {
    super.initState();
    final budget = widget.initialBudget;
    _titleController = TextEditingController(text: budget?.title ?? '');
    _limitController = TextEditingController(
      text: budget == null ? '' : budget.limit.toStringAsFixed(0),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(budgetFormCategoryProvider.notifier).state =
          budget?.category ?? '';
      ref.read(budgetFormWalletProvider.notifier).state =
          budget?.walletName ?? _wallets.first;

      final now = DateTime.now();
      final startDate = _toCurrentMonthWithDay(budget?.startDate.day ?? 1);
      var endDate = _toCurrentMonthWithDay(
        budget?.endDate.day ?? DateTime(now.year, now.month + 1, 0).day,
      );

      if (endDate.isBefore(startDate)) {
        endDate = startDate;
      }

      ref.read(budgetFormStartDateProvider.notifier).state = startDate;
      ref.read(budgetFormEndDateProvider.notifier).state = endDate;

      _loadChoices();
    });
  }

  Future<void> _loadChoices() async {
    await Future.wait([
      CategoriesRepository.instance.loadCategories(forceRefresh: true),
      AccountsRepository.instance.loadAccounts(forceRefresh: true),
    ]);

    final categoryNames = CategoriesRepository.instance
        .categoriesByTypes(const <String>{'expense'})
        .map((item) => item.name)
        .toList(growable: false);
    final walletNames = AccountsRepository.instance.walletNames();

    _categories
      ..clear()
      ..addAll(categoryNames);
    _wallets
      ..clear()
      ..add('Tất cả ví')
      ..addAll(walletNames);

    final selectedCategory = ref.read(budgetFormCategoryProvider);
    if (selectedCategory.isEmpty || !_categories.contains(selectedCategory)) {
      ref.read(budgetFormCategoryProvider.notifier).state =
          _categories.isEmpty ? '' : _categories.first;
    }
    final selectedWallet = ref.read(budgetFormWalletProvider);
    if (!_wallets.contains(selectedWallet)) {
      ref.read(budgetFormWalletProvider.notifier).state = _wallets.first;
    }

    ref.read(budgetFormLoadingChoicesProvider.notifier).state = false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(budgetFormCategoryProvider);
    final selectedWallet = ref.watch(budgetFormWalletProvider);
    final isLoadingChoices = ref.watch(budgetFormLoadingChoicesProvider);
    final startDate = ref.watch(budgetFormStartDateProvider);
    final endDate = ref.watch(budgetFormEndDateProvider);
    final scheme = Theme.of(context).colorScheme;
    final isEditing = widget.initialBudget != null;

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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isEditing ? 'Chỉnh sửa ngân sách' : 'Tạo ngân sách mới',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Thiết lập hạn mức theo danh mục và thời gian theo dõi.',
                  style: TextStyle(color: scheme.outline),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Tên ngân sách',
                    hintText: 'Ví dụ: Chi tiêu ăn uống tháng này',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên ngân sách';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _categories.contains(selectedCategory)
                      ? selectedCategory
                      : null,
                  disabledHint: Text(
                    LanguageService.tr(
                      vi: 'Không có danh mục chi tiêu',
                      en: 'No expense categories available',
                    ),
                  ),
                  decoration: const InputDecoration(labelText: 'Danh mục'),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(budgetFormCategoryProvider.notifier).state = value;
                    }
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng chọn danh mục';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _wallets.contains(selectedWallet)
                      ? selectedWallet
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Áp dụng cho ví/tài khoản',
                  ),
                  items: _wallets.map((wallet) {
                    return DropdownMenuItem(value: wallet, child: Text(wallet));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(budgetFormWalletProvider.notifier).state = value;
                    }
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _limitController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Hạn mức',
                    suffixText: 'VNĐ',
                  ),
                  validator: _validateMoney,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'Từ ngày',
                        value: _formatDay(startDate),
                        onTap: () => _pickStartDate(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateField(
                        label: 'Đến ngày',
                        value: _formatDay(endDate),
                        onTap: () => _pickEndDate(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: isLoadingChoices ? null : _submit,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(
                      isEditing ? 'Cập nhật ngân sách' : 'Tạo ngân sách',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateMoney(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số tiền';
    }
    final parsed = double.tryParse(value.replaceAll(',', '').trim());
    if (parsed == null || parsed < 0) {
      return 'Số tiền không hợp lệ';
    }
    return null;
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, 1);
    final lastDate = DateTime(now.year, now.month + 1, 0);
    final picked = await showDatePicker(
      context: context,
      initialDate: ref.read(budgetFormStartDateProvider),
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked == null) return;

    final nextStart = _toCurrentMonthWithDay(picked.day);
    final currentEnd = ref.read(budgetFormEndDateProvider);
    ref.read(budgetFormStartDateProvider.notifier).state = nextStart;
    if (currentEnd.isBefore(nextStart)) {
      ref.read(budgetFormEndDateProvider.notifier).state = nextStart;
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, 1);
    final lastDate = DateTime(now.year, now.month + 1, 0);
    final picked = await showDatePicker(
      context: context,
      initialDate: ref.read(budgetFormEndDateProvider),
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked == null) return;

    final selected = _toCurrentMonthWithDay(picked.day);
    final currentStart = ref.read(budgetFormStartDateProvider);
    ref.read(budgetFormEndDateProvider.notifier).state =
        selected.isBefore(currentStart) ? currentStart : selected;
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final selectedCategory = ref.read(budgetFormCategoryProvider);
    final selectedWallet = ref.read(budgetFormWalletProvider);
    final startDate = ref.read(budgetFormStartDateProvider);
    final endDate = ref.read(budgetFormEndDateProvider);

    if (selectedCategory.isEmpty || !_categories.contains(selectedCategory)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LanguageService.tr(
              vi: 'Vui lòng tạo và chọn danh mục chi tiêu hợp lệ trong Cài đặt tài khoản',
              en: 'Please create and select a valid expense category in account settings',
            ),
          ),
        ),
      );
      return;
    }

    final budget = Budget(
      id:
          widget.initialBudget?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      category: selectedCategory,
      walletName: selectedWallet,
      limit: double.parse(_limitController.text.replaceAll(',', '').trim()),
      spent: widget.initialBudget?.spent ?? 0.0,
      startDate: startDate,
      endDate: endDate,
      color: CategoryHelper.colorFor(selectedCategory),
      icon: CategoryHelper.iconFor(selectedCategory),
    );

    Navigator.pop(context, budget);
  }

  DateTime _toCurrentMonthWithDay(int day) {
    final now = DateTime.now();
    final maxDay = DateTime(now.year, now.month + 1, 0).day;
    final safeDay = day.clamp(1, maxDay);
    return DateTime(now.year, now.month, safeDay);
  }

  String _formatDay(DateTime date) {
    return 'Ngày ${date.day.toString().padLeft(2, '0')}';
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Row(
          children: [
            Icon(Icons.event_outlined, size: 18, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Category icon/color mapping is now centralized in CategoryHelper.

