import 'package:flutter/material.dart';

import '../../../core/services/language_service.dart';
import '../../shared/widgets/category_helper.dart';
import '../models/budget.dart';

class BudgetForm extends StatefulWidget {
  final Budget? initialBudget;

  const BudgetForm({super.key, this.initialBudget});

  @override
  State<BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends State<BudgetForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _categoryController;
  late final TextEditingController _limitController;
  late final TextEditingController _spentController;

  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final budget = widget.initialBudget;
    _titleController = TextEditingController(text: budget?.title ?? '');
    _categoryController = TextEditingController(text: budget?.category ?? '');
    _limitController = TextEditingController(
      text: budget == null ? '' : budget.limit.toStringAsFixed(0),
    );
    _spentController = TextEditingController(
      text: budget == null ? '0' : budget.spent.toStringAsFixed(0),
    );
    _date = budget?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _limitController.dispose();
    _spentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  isEditing
                      ? LanguageService.tr(vi: 'Chỉnh sửa ngân sách', en: 'Edit budget')
                      : LanguageService.tr(vi: 'Tạo ngân sách mới', en: 'Create new budget'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  LanguageService.tr(
                    vi: 'Thiết lập hạn mức theo danh mục và thời gian theo dõi.',
                    en: 'Set spending limit by category and tracking time.',
                  ),
                  style: TextStyle(color: scheme.outline),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: LanguageService.tr(vi: 'Tên ngân sách', en: 'Budget name'),
                    hintText: LanguageService.tr(
                      vi: 'Ví dụ: Chi tiêu ăn uống tháng này',
                      en: 'Example: Food spending this month',
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return LanguageService.tr(
                        vi: 'Vui lòng nhập tên ngân sách',
                        en: 'Please enter budget name',
                      );
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _categoryController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: LanguageService.tr(vi: 'Danh mục', en: 'Category'),
                    hintText: LanguageService.tr(
                      vi: 'Ví dụ: Ăn uống, Di chuyển',
                      en: 'Example: Food, Transport',
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return LanguageService.tr(
                        vi: 'Vui lòng nhập danh mục',
                        en: 'Please enter category',
                      );
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _limitController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: LanguageService.tr(vi: 'Hạn mức', en: 'Limit'),
                          suffixText: 'VNĐ',
                        ),
                        validator: _validateMoney,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _spentController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: LanguageService.tr(vi: 'Đã chi', en: 'Spent'),
                          suffixText: 'VNĐ',
                        ),
                        validator: _validateMoney,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: LanguageService.tr(vi: 'Ngày', en: 'Date'),
                        value: _formatDate(_date),
                        onTap: () => _pickDate(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(
                      isEditing
                          ? LanguageService.tr(vi: 'Cập nhật ngân sách', en: 'Update budget')
                          : LanguageService.tr(vi: 'Tạo ngân sách', en: 'Create budget'),
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
      return LanguageService.tr(vi: 'Vui lòng nhập số tiền', en: 'Please enter amount');
    }
    final parsed = double.tryParse(value.replaceAll(',', '').trim());
    if (parsed == null || parsed < 0) {
      return LanguageService.tr(vi: 'Số tiền không hợp lệ', en: 'Invalid amount');
    }
    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    setState(() {
      _date = picked;
    });
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final budget = Budget(
      id:
          widget.initialBudget?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      category: _categoryController.text.trim(),
      limit: double.parse(_limitController.text.replaceAll(',', '').trim()),
      spent: double.parse(_spentController.text.replaceAll(',', '').trim()),
      date: _date,
      color: CategoryHelper.colorFor(_categoryController.text.trim()),
      icon: CategoryHelper.iconFor(_categoryController.text.trim()),
    );

    Navigator.pop(context, budget);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
