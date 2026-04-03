import 'package:flutter/material.dart';

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
                TextFormField(
                  controller: _categoryController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Danh mục',
                    hintText: 'Ví dụ: Ăn uống, Di chuyển',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập danh mục';
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
                        decoration: const InputDecoration(
                          labelText: 'Hạn mức',
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
                        decoration: const InputDecoration(
                          labelText: 'Đã chi',
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
                        label: 'Ngày',
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
      color: _budgetColorForCategory(_categoryController.text.trim()),
      icon: _budgetIconForCategory(_categoryController.text.trim()),
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

Color _budgetColorForCategory(String category) {
  final normalized = category.toLowerCase();
  if (normalized.contains('ăn') || normalized.contains('food')) {
    return const Color(0xFFE07A5F);
  }
  if (normalized.contains('di chuyển') || normalized.contains('transport')) {
    return const Color(0xFF3D5A80);
  }
  if (normalized.contains('nhà') || normalized.contains('rent')) {
    return const Color(0xFF81B29A);
  }
  if (normalized.contains('mua sắm') || normalized.contains('shop')) {
    return const Color(0xFF9B5DE5);
  }
  return const Color(0xFF0D7377);
}

IconData _budgetIconForCategory(String category) {
  final normalized = category.toLowerCase();
  if (normalized.contains('ăn') || normalized.contains('food')) {
    return Icons.restaurant_outlined;
  }
  if (normalized.contains('di chuyển') || normalized.contains('transport')) {
    return Icons.directions_car_outlined;
  }
  if (normalized.contains('nhà') || normalized.contains('rent')) {
    return Icons.home_outlined;
  }
  if (normalized.contains('mua sắm') || normalized.contains('shop')) {
    return Icons.shopping_bag_outlined;
  }
  return Icons.account_balance_wallet_outlined;
}
