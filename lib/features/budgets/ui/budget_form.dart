import 'package:flutter/material.dart';

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
  late final TextEditingController _limitController;

  String _selectedCategory = 'Ăn uống';
  final List<String> _categories = [
    'Ăn uống',
    'Di chuyển',
    'Mua sắm',
    'Nhà ở',
    'Giải trí',
    'Sức khỏe',
    'Giáo dục',
    'Hóa đơn',
  ];

  String _selectedWallet = 'Tất cả ví';
  final List<String> _wallets = [
    'Tất cả ví',
    'Tiền mặt',
    'Vietcombank',
    'Techcombank',
    'Momo',
    'ZaloPay',
  ];

  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    final budget = widget.initialBudget;
    _titleController = TextEditingController(text: budget?.title ?? '');
    _limitController = TextEditingController(
      text: budget == null ? '' : budget.limit.toStringAsFixed(0),
    );

    if (budget != null && !_categories.contains(budget.category)) {
      _categories.add(budget.category);
    }
    _selectedCategory = budget?.category ?? _categories.first;

    if (budget != null && !_wallets.contains(budget.walletName)) {
      _wallets.add(budget.walletName);
    }
    _selectedWallet = budget?.walletName ?? _wallets.first;

    final now = DateTime.now();
    _startDate = _toCurrentMonthWithDay(budget?.startDate.day ?? 1);
    _endDate = _toCurrentMonthWithDay(
      budget?.endDate.day ?? DateTime(now.year, now.month + 1, 0).day,
    );

    if (_endDate.isBefore(_startDate)) {
      _endDate = _startDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _limitController.dispose();
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
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Danh mục'),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
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
                  initialValue: _selectedWallet,
                  decoration: const InputDecoration(
                    labelText: 'Áp dụng cho ví/tài khoản',
                  ),
                  items: _wallets.map((wallet) {
                    return DropdownMenuItem(value: wallet, child: Text(wallet));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedWallet = value;
                      });
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
                        value: _formatDay(_startDate),
                        onTap: () => _pickStartDate(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateField(
                        label: 'Đến ngày',
                        value: _formatDay(_endDate),
                        onTap: () => _pickEndDate(),
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

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, 1);
    final lastDate = DateTime(now.year, now.month + 1, 0);
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked == null) return;

    setState(() {
      _startDate = _toCurrentMonthWithDay(picked.day);
      if (_endDate.isBefore(_startDate)) {
        _endDate = _startDate;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, 1);
    final lastDate = DateTime(now.year, now.month + 1, 0);
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked == null) return;

    setState(() {
      final selected = _toCurrentMonthWithDay(picked.day);
      _endDate = selected.isBefore(_startDate) ? _startDate : selected;
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
      category: _selectedCategory,
      walletName: _selectedWallet,
      limit: double.parse(_limitController.text.replaceAll(',', '').trim()),
      spent: widget.initialBudget?.spent ?? 0.0,
      startDate: _startDate,
      endDate: _endDate,
      color: CategoryHelper.colorFor(_selectedCategory),
      icon: CategoryHelper.iconFor(_selectedCategory),
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
