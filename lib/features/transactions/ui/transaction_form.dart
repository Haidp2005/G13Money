import 'package:flutter/material.dart';
import '../../../core/services/language_service.dart';
import '../../shared/widgets/category_helper.dart';

class TransactionForm extends StatefulWidget {
  const TransactionForm({super.key});

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isIncome = false;
  String _selectedCategory = 'Ăn uống';
  String _selectedWallet = 'Chính';

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, ColorScheme scheme) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: scheme.copyWith(
              primary: scheme.primary,
              onPrimary: scheme.onPrimary,
              onSurface: scheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // TODO: Save transaction
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: scheme.onSurface, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          LanguageService.tr(vi: 'Thêm giao dịch', en: 'Add transaction'),
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(Icons.check_rounded, color: scheme.primary, size: 28),
              onPressed: _submitForm,
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Type Toggle ──
              _buildTypeToggle(scheme),
              const SizedBox(height: 24),
              // ── Amount Input ──
              _buildFieldLabel(LanguageService.tr(vi: 'Số tiền', en: 'Amount'), scheme),
              const SizedBox(height: 10),
              _buildAmountField(scheme),
              const SizedBox(height: 24),
              // ── Category Selector ──
              _buildFieldLabel(LanguageService.tr(vi: 'Hạng mục', en: 'Category'), scheme),
              const SizedBox(height: 10),
              _buildSelectorField(
                icon: CategoryHelper.iconFor(_selectedCategory),
                label: _selectedCategory,
                color: CategoryHelper.colorFor(_selectedCategory),
                scheme: scheme,
                onTap: () {
                  // TODO: Category selection
                },
              ),
              const SizedBox(height: 24),
              // ── Wallet Selector ──
              _buildFieldLabel(LanguageService.tr(vi: 'Tài khoản', en: 'Account'), scheme),
              const SizedBox(height: 10),
              _buildSelectorField(
                icon: Icons.account_balance_wallet_rounded,
                label: _selectedWallet,
                color: scheme.secondary,
                scheme: scheme,
                onTap: () {
                  // TODO: Wallet selection
                },
              ),
              const SizedBox(height: 24),
              // ── Date Selector ──
              _buildFieldLabel(LanguageService.tr(vi: 'Ngày', en: 'Date'), scheme),
              const SizedBox(height: 10),
              _buildSelectorField(
                icon: Icons.calendar_today_rounded,
                label: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                color: scheme.tertiary,
                scheme: scheme,
                onTap: () => _selectDate(context, scheme),
              ),
              const SizedBox(height: 24),
              // ── Note Field ──
              _buildFieldLabel(LanguageService.tr(vi: 'Ghi chú', en: 'Note'), scheme),
              const SizedBox(height: 10),
              _buildNoteField(scheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, ColorScheme scheme) {
    return Text(
      label,
      style: TextStyle(
        color: scheme.outline,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTypeToggle(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _toggleItem(
              label: LanguageService.tr(vi: 'Chi tiêu', en: 'Expense'),
              isSelected: !_isIncome,
              selectedColor: const Color(0xFFFF6B6B),
              onTap: () => setState(() => _isIncome = false),
              scheme: scheme,
            ),
          ),
          Expanded(
            child: _toggleItem(
              label: LanguageService.tr(vi: 'Thu nhập', en: 'Income'),
              isSelected: _isIncome,
              selectedColor: const Color(0xFF2DCC5A),
              onTap: () => setState(() => _isIncome = true),
              scheme: scheme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleItem({
    required String label,
    required bool isSelected,
    required Color selectedColor,
    required VoidCallback onTap,
    required ColorScheme scheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? scheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? selectedColor : scheme.outline,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField(ColorScheme scheme) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(
          color: scheme.onSurface,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          hintText: '0',
          hintStyle: TextStyle(
            color: scheme.outlineVariant,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(
              _isIncome ? Icons.add_rounded : Icons.remove_rounded,
              color: _isIncome ? const Color(0xFF2DCC5A) : const Color(0xFFFF6B6B),
              size: 32,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixText: 'đ ',
          suffixStyle: TextStyle(
            color: scheme.outline,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return LanguageService.tr(vi: 'Vui lòng nhập số tiền', en: 'Please enter amount');
          }
          if (double.tryParse(value.replaceAll(',', '')) == null) {
            return LanguageService.tr(vi: 'Số tiền không hợp lệ', en: 'Invalid amount');
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSelectorField({
    required IconData icon,
    required String label,
    required Color color,
    required ColorScheme scheme,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: scheme.outline, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteField(ColorScheme scheme) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: _noteController,
        maxLines: 3,
        style: TextStyle(
          color: scheme.onSurface,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: LanguageService.tr(vi: 'Nhập ghi chú...', en: 'Enter a note...'),
          hintStyle: TextStyle(
            color: scheme.outlineVariant,
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}
