import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/language_service.dart';
import '../../shared/widgets/category_helper.dart';

enum _TransactionType { expense, income, debt }

class AddTransactionFormPage extends StatefulWidget {
  const AddTransactionFormPage({super.key});

  @override
  State<AddTransactionFormPage> createState() => _AddTransactionFormPageState();
}

class _AddTransactionFormPageState extends State<AddTransactionFormPage> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  _TransactionType _type = _TransactionType.expense;
  final String _walletName = 'Tiền mặt';
  String _selectedCategory = 'Ăn uống';
  DateTime _selectedDate = DateTime.now();
  final List<Uint8List> _attachments = <Uint8List>[];

  static const List<String> _expenseCategories = <String>[
    'Ăn uống',
    'Di chuyển',
    'Mua sắm',
    'Nhà ở',
    'Giải trí',
    'Sức khỏe',
    'Giáo dục',
    'Hóa đơn',
  ];

  static const List<String> _incomeCategories = <String>[
    'Lương',
    'Thưởng',
    'Thu nhập khác',
  ];

  static const List<String> _debtCategories = <String>[
    'Cho vay',
    'Đi vay',
    'Trả nợ',
    'Thu nợ',
  ];

  List<String> get _currentCategories {
    switch (_type) {
      case _TransactionType.expense:
        return _expenseCategories;
      case _TransactionType.income:
        return _incomeCategories;
      case _TransactionType.debt:
        return _debtCategories;
    }
  }

  @override
  void initState() {
    super.initState();
    _amountController.text = '0';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: Locale(LanguageService.isVietnamese ? 'vi' : 'en'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _changeDateBy(int days) async {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  Future<void> _showCategorySelector() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  LanguageService.tr(vi: 'Chọn danh mục', en: 'Select category'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _currentCategories.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final category = _currentCategories[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: CategoryHelper.colorFor(category)
                              .withValues(alpha: 0.14),
                          child: Icon(
                            CategoryHelper.iconFor(category),
                            color: CategoryHelper.colorFor(category),
                          ),
                        ),
                        title: Text(category),
                        trailing: category == _selectedCategory
                            ? const Icon(Icons.check_circle, color: Color(0xFF22B45E))
                            : null,
                        onTap: () => Navigator.of(context).pop(category),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedCategory = selected;
      });
    }
  }

  Future<void> _showAttachmentActions() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: Text(LanguageService.tr(vi: 'Chụp ảnh', en: 'Take photo')),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text(LanguageService.tr(vi: 'Chọn từ thiết bị', en: 'Choose from device')),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    final pickedFile = await _imagePicker.pickImage(source: source, imageQuality: 85);
    if (pickedFile == null) {
      return;
    }

    final bytes = await pickedFile.readAsBytes();
    setState(() {
      _attachments.add(bytes);
    });
  }

  void _changeType(_TransactionType type) {
    setState(() {
      _type = type;
      _selectedCategory = _currentCategories.first;
    });
  }

  String _dateLabel() {
    final weekday = <int, String>{
      DateTime.monday: 'Thứ Hai',
      DateTime.tuesday: 'Thứ Ba',
      DateTime.wednesday: 'Thứ Tư',
      DateTime.thursday: 'Thứ Năm',
      DateTime.friday: 'Thứ Sáu',
      DateTime.saturday: 'Thứ Bảy',
      DateTime.sunday: 'Chủ Nhật',
    }[_selectedDate.weekday]!;
    final day = _selectedDate.day.toString().padLeft(2, '0');
    final month = _selectedDate.month.toString().padLeft(2, '0');
    final year = _selectedDate.year.toString();
    return '$weekday, $day/$month/$year';
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LanguageService.tr(
              vi: 'Vui lòng nhập số tiền hợp lệ',
              en: 'Please enter a valid amount',
            ),
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          LanguageService.tr(
            vi: 'Đã lưu giao dịch mẫu',
            en: 'Sample transaction saved',
          ),
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF7F8FB);
    const cardColor = Colors.white;
    const muted = Color(0xFF8C919E);
    const valueGreen = Color(0xFF22B45E);

    final selectedCategoryColor = CategoryHelper.colorFor(_selectedCategory);
    final selectedCategoryIcon = CategoryHelper.iconFor(_selectedCategory);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF171A21),
        elevation: 0,
        centerTitle: true,
        title: Text(
          LanguageService.tr(vi: 'Thêm giao dịch', en: 'Add transaction'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 22),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE8EAF0)),
                  ),
                  child: Column(
                    children: [
                      // ── Type tabs
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3F8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Row(
                          children: [
                            _typeChip(
                              label: 'Khoản chi',
                              selected: _type == _TransactionType.expense,
                              onTap: () => _changeType(_TransactionType.expense),
                            ),
                            _typeChip(
                              label: 'Khoản thu',
                              selected: _type == _TransactionType.income,
                              onTap: () => _changeType(_TransactionType.income),
                            ),
                            _typeChip(
                              label: 'Vay/Nợ',
                              selected: _type == _TransactionType.debt,
                              onTap: () => _changeType(_TransactionType.debt),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ── Wallet
                      _plainRow(
                        leading: const Icon(Icons.account_balance_wallet_outlined, size: 22, color: Color(0xFF8C919E)),
                        child: Text(
                          _walletName,
                          style: const TextStyle(fontSize: 16, color: Color(0xFF181B23), fontWeight: FontWeight.w500),
                        ),
                      ),
                      const Divider(height: 20, thickness: 1, color: Color(0xFFEEF0F5)),
                      // ── Amount
                      _plainRow(
                        leading: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            color: const Color(0xFFF1F3F8),
                          ),
                          child: const Text('VND', style: TextStyle(color: muted, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          style: const TextStyle(
                            fontSize: 42,
                            height: 1.1,
                            fontWeight: FontWeight.w600,
                            color: valueGreen,
                          ),
                        ),
                      ),
                      const Divider(height: 20, thickness: 1, color: Color(0xFFEEF0F5)),
                      // ── Category
                      InkWell(
                        onTap: _showCategorySelector,
                        borderRadius: BorderRadius.circular(12),
                        child: _plainRow(
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: selectedCategoryColor.withValues(alpha: 0.16),
                            child: Icon(selectedCategoryIcon, color: selectedCategoryColor, size: 18),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedCategory,
                                  style: const TextStyle(fontSize: 16, color: Color(0xFF181B23), fontWeight: FontWeight.w500),
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, size: 22, color: muted),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 20, thickness: 1, color: Color(0xFFEEF0F5)),
                      // ── Note
                      _plainRow(
                        leading: const Icon(Icons.subject_rounded, size: 22, color: Color(0xFF8C919E)),
                        child: TextField(
                          controller: _noteController,
                          decoration: InputDecoration(
                            hintText: LanguageService.tr(vi: 'Thêm ghi chú', en: 'Add note'),
                            hintStyle: const TextStyle(fontSize: 16, color: muted),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const Divider(height: 20, thickness: 1, color: Color(0xFFEEF0F5)),
                      // ── Date
                      _plainRow(
                        leading: const Icon(Icons.calendar_month_outlined, size: 22, color: Color(0xFF8C919E)),
                        child: Row(
                          children: [
                            _dateButton(Icons.chevron_left_rounded, () => _changeDateBy(-1)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: _pickDate,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: const Color(0xFFF1F3F8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _dateLabel(),
                                    style: const TextStyle(
                                      color: valueGreen,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _dateButton(Icons.chevron_right_rounded, () => _changeDateBy(1)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ── Add detail
                      Center(
                        child: TextButton.icon(
                          onPressed: _showAttachmentActions,
                          icon: const Icon(Icons.add_photo_alternate_outlined, size: 18, color: valueGreen),
                          label: Text(
                            LanguageService.tr(vi: 'Thêm hình ảnh / chi tiết', en: 'Add photo / details'),
                            style: const TextStyle(
                              color: valueGreen,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      if (_attachments.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 76,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _attachments.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(
                                      _attachments[index],
                                      width: 76,
                                      height: 76,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _attachments.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: const BoxDecoration(
                                          color: Color(0xAA000000),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF22B45E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    LanguageService.tr(vi: 'Lưu', en: 'Save'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF22B45E).withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF22B45E) : const Color(0xFF5A5F6E),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _plainRow({required Widget leading, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 44, child: Center(child: leading)),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _dateButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F8),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, color: const Color(0xFF22B45E), size: 22),
      ),
    );
  }
}
