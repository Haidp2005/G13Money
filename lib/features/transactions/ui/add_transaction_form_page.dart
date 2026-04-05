import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../accounts/data/accounts_repository.dart';
import '../../accounts/data/categories_repository.dart';
import '../../accounts/models/account.dart';
import '../../accounts/models/category_item.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/supabase_storage_service.dart';
import '../data/transactions_repository.dart';
import '../state/add_transaction_form_state.dart';
import '../../shared/widgets/category_helper.dart';

class TransactionFormInitialData {
  final String transactionId;
  final String note;
  final String walletName;
  final String category;
  final double amount;
  final DateTime date;
  final bool isIncome;
  final List<String> attachmentUrls;

  const TransactionFormInitialData({
    required this.transactionId,
    required this.note,
    required this.walletName,
    required this.category,
    required this.amount,
    required this.date,
    required this.isIncome,
    this.attachmentUrls = const <String>[],
  });
}

class AddTransactionFormPage extends ConsumerStatefulWidget {
  final TransactionFormInitialData? initialData;

  const AddTransactionFormPage({super.key, this.initialData});

  @override
  ConsumerState<AddTransactionFormPage> createState() => _AddTransactionFormPageState();
}

class _AddTransactionFormPageState extends ConsumerState<AddTransactionFormPage> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  final List<Account> _wallets = [];
  final List<CategoryItem> _categories = [];
  List<String> _existingAttachmentUrls = <String>[];

  bool get _isEditMode => widget.initialData != null;

  List<String> get _currentCategories {
    final currentType = ref.read(transactionTypeProvider);
    final targetType = currentType == TransactionFormType.income ? 'income' : 'expense';
    return _categories
        .where((item) => item.type.trim().toLowerCase() == targetType)
        .map((item) => item.name)
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialData;
    if (initial == null) {
      _amountController.text = '0';
    } else {
      _amountController.text = initial.amount.toStringAsFixed(0);
      _noteController.text = initial.note;
      _existingAttachmentUrls = List<String>.from(initial.attachmentUrls);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final seed = widget.initialData;
      if (seed != null) {
        ref.read(transactionSelectedWalletProvider.notifier).state =
            seed.walletName;
        ref.read(transactionSelectedCategoryProvider.notifier).state =
            seed.category;
        ref.read(transactionSelectedDateProvider.notifier).state = seed.date;
        ref.read(transactionTypeProvider.notifier).state = seed.isIncome
            ? TransactionFormType.income
            : TransactionFormType.expense;
      }
      _loadMetaData();
    });
  }

  Future<void> _loadMetaData() async {
    await Future.wait([
      AccountsRepository.instance.loadAccounts(forceRefresh: true),
      CategoriesRepository.instance.loadCategories(forceRefresh: true),
    ]);

    _wallets
      ..clear()
      ..addAll(AccountsRepository.instance.accounts);
    _categories
      ..clear()
      ..addAll(CategoriesRepository.instance.categories);

    final currentCategories = _currentCategories;
    final selectedCategory = ref.read(transactionSelectedCategoryProvider);
    if (selectedCategory.trim().isEmpty && currentCategories.isNotEmpty) {
      ref.read(transactionSelectedCategoryProvider.notifier).state =
          currentCategories.first;
    }
    final selectedWalletName = ref.read(transactionSelectedWalletProvider);
    if (selectedWalletName.trim().isEmpty && _wallets.isNotEmpty) {
      ref.read(transactionSelectedWalletProvider.notifier).state =
          _wallets.first.name;
    }

    ref.read(transactionMetaLoadingProvider.notifier).state = false;
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
      initialDate: ref.read(transactionSelectedDateProvider),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: Locale(LanguageService.isVietnamese ? 'vi' : 'en'),
    );
    if (picked != null) {
      ref.read(transactionSelectedDateProvider.notifier).state = picked;
    }
  }

  Future<void> _changeDateBy(int days) async {
    final selectedDate = ref.read(transactionSelectedDateProvider);
    ref.read(transactionSelectedDateProvider.notifier).state =
        selectedDate.add(Duration(days: days));
  }

  Future<void> _showCategorySelector() async {
    final selectedCategory = ref.read(transactionSelectedCategoryProvider);
    try {
      await CategoriesRepository.instance.loadCategories(forceRefresh: true);
      _categories
        ..clear()
        ..addAll(CategoriesRepository.instance.categories);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      return;
    }

    if (!mounted) return;

    if (_currentCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LanguageService.tr(
              vi: 'Không có danh mục phù hợp. Hãy tạo danh mục trong Cài đặt tài khoản.',
              en: 'No matching category. Please create categories in account settings.',
            ),
          ),
        ),
      );
      return;
    }

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
                        trailing: category == selectedCategory
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
      ref.read(transactionSelectedCategoryProvider.notifier).state = selected;
    }
  }

  Future<void> _showWalletSelector() async {
    final selectedWalletName = ref.read(transactionSelectedWalletProvider);
    try {
      await AccountsRepository.instance.loadAccounts(forceRefresh: true);
      _wallets
        ..clear()
        ..addAll(AccountsRepository.instance.accounts);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      return;
    }

    if (!mounted) return;

    if (_wallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LanguageService.tr(
              vi: 'Không có ví/tài khoản. Hãy tạo trong Cài đặt tài khoản.',
              en: 'No wallet/account found. Please create one in account settings.',
            ),
          ),
        ),
      );
      return;
    }

    final walletColors = [
      const Color(0xFF22B45E),
      const Color(0xFF4F6EF7),
      const Color(0xFFFF8C42),
      const Color(0xFFE040FB),
      const Color(0xFF00BCD4),
      const Color(0xFFFF5252),
    ];

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Chọn ví',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF171A21),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3F8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF5A5F6E)),
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Wallet list
                ...List.generate(_wallets.length, (index) {
                  final wallet = _wallets[index];
                  final isSelected = wallet.name == selectedWalletName;
                  final avatarColor = walletColors[index % walletColors.length];

                  return GestureDetector(
                    onTap: () => Navigator.of(context).pop(wallet.name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF22B45E).withValues(alpha: 0.07)
                            : const Color(0xFFF7F8FB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF22B45E).withValues(alpha: 0.5)
                              : const Color(0xFFE8EAF0),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar icon
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  avatarColor.withValues(alpha: 0.85),
                                  avatarColor,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: avatarColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Name
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  wallet.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: const Color(0xFF171A21),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  LanguageService.tr(vi: 'Ví cá nhân', en: 'Personal wallet'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF8C919E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Checkmark
                          if (isSelected)
                            Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                color: Color(0xFF22B45E),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                            )
                          else
                            const SizedBox(width: 26),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      ref.read(transactionSelectedWalletProvider.notifier).state = selected;
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
    final current = ref.read(transactionAttachmentsProvider);
    ref.read(transactionAttachmentsProvider.notifier).state =
        List<Uint8List>.unmodifiable(<Uint8List>[...current, bytes]);
  }

  void _changeType(TransactionFormType type) {
    ref.read(transactionTypeProvider.notifier).state = type;
    final categories = _currentCategories;
    ref.read(transactionSelectedCategoryProvider.notifier).state =
        categories.isEmpty ? '' : categories.first;
  }

  String _dateLabel() {
    final selectedDate = ref.read(transactionSelectedDateProvider);
    final weekday = <int, String>{
      DateTime.monday: 'Thứ Hai',
      DateTime.tuesday: 'Thứ Ba',
      DateTime.wednesday: 'Thứ Tư',
      DateTime.thursday: 'Thứ Năm',
      DateTime.friday: 'Thứ Sáu',
      DateTime.saturday: 'Thứ Bảy',
      DateTime.sunday: 'Chủ Nhật',
    }[selectedDate.weekday]!;
    final day = selectedDate.day.toString().padLeft(2, '0');
    final month = selectedDate.month.toString().padLeft(2, '0');
    final year = selectedDate.year.toString();
    return '$weekday, $day/$month/$year';
  }

  Future<void> _submit() async {
    final selectedWalletName = ref.read(transactionSelectedWalletProvider);
    final selectedCategory = ref.read(transactionSelectedCategoryProvider);
    final selectedDate = ref.read(transactionSelectedDateProvider);
    final selectedType = ref.read(transactionTypeProvider);

    if (selectedWalletName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LanguageService.tr(
              vi: 'Vui lòng chọn ví/tài khoản',
              en: 'Please select a wallet/account',
            ),
          ),
        ),
      );
      return;
    }

    if (selectedCategory.trim().isEmpty ||
      !_currentCategories.contains(selectedCategory)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LanguageService.tr(
              vi: 'Danh mục không hợp lệ cho loại giao dịch đã chọn',
              en: 'Invalid category for selected transaction type',
            ),
          ),
        ),
      );
      return;
    }

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

    final note = _noteController.text.trim();
    final title = note.isEmpty ? selectedCategory : note;
    final isIncome = selectedType == TransactionFormType.income;
    final normalizedAmount = amount.abs();
    final attachments = ref.read(transactionAttachmentsProvider);

    ref.read(transactionSubmittingProvider.notifier).state = true;

    try {
      final uid = AuthService.currentUserId;
      if (uid == null) {
        throw Exception('Bạn chưa đăng nhập');
      }

      final originalAttachmentUrls = _isEditMode
          ? widget.initialData!.attachmentUrls
          : const <String>[];

      final txId = _isEditMode
          ? widget.initialData!.transactionId
          : DateTime.now().microsecondsSinceEpoch.toString();

      final uploadedAttachmentUrls = attachments.isEmpty
          ? const <String>[]
          : await SupabaseStorageService.uploadTransactionImages(
              uid: uid,
              transactionId: txId,
              images: attachments,
            );

      final mergedAttachmentUrls = <String>[
        ..._existingAttachmentUrls,
        ...uploadedAttachmentUrls,
      ];

      if (_isEditMode) {
        await TransactionsRepository.instance.updateTransaction(
          id: widget.initialData!.transactionId,
          title: title,
          category: selectedCategory,
          walletName: selectedWalletName,
          amount: normalizedAmount,
          date: selectedDate,
          isIncome: isIncome,
          attachmentUrls: mergedAttachmentUrls,
        );

        final removedUrls = originalAttachmentUrls
            .where((url) => !_existingAttachmentUrls.contains(url))
            .toList(growable: false);
        if (removedUrls.isNotEmpty) {
          try {
            await SupabaseStorageService.deleteTransactionImagesByPublicUrls(
              removedUrls,
            );
          } catch (_) {
            // Keep transaction update success even if old storage cleanup fails.
          }
        }
      } else {
        await TransactionsRepository.instance.addTransaction(
          title: title,
          category: selectedCategory,
          walletName: selectedWalletName,
          amount: normalizedAmount,
          date: selectedDate,
          isIncome: isIncome,
          attachmentUrls: mergedAttachmentUrls,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ref.read(transactionSubmittingProvider.notifier).state = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          LanguageService.tr(
            vi: _isEditMode ? 'Đã cập nhật giao dịch' : 'Đã lưu giao dịch',
            en: _isEditMode ? 'Transaction updated' : 'Transaction saved',
          ),
        ),
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final transactionType = ref.watch(transactionTypeProvider);
    final selectedWalletName = ref.watch(transactionSelectedWalletProvider);
    final selectedCategory = ref.watch(transactionSelectedCategoryProvider);
    final attachments = ref.watch(transactionAttachmentsProvider);
    final isSubmitting = ref.watch(transactionSubmittingProvider);
    final isMetaLoading = ref.watch(transactionMetaLoadingProvider);

    const bgColor = Color(0xFFF7F8FB);
    const cardColor = Colors.white;
    const muted = Color(0xFF8C919E);
    const valueGreen = Color(0xFF22B45E);

    final selectedCategoryColor = CategoryHelper.colorFor(selectedCategory);
    final selectedCategoryIcon = CategoryHelper.iconFor(selectedCategory);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF171A21),
        elevation: 0,
        centerTitle: true,
        title: Text(
          LanguageService.tr(
            vi: _isEditMode ? 'Sửa giao dịch' : 'Thêm giao dịch',
            en: _isEditMode ? 'Edit transaction' : 'Add transaction',
          ),
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
                              selected: transactionType == TransactionFormType.expense,
                              onTap: () => _changeType(TransactionFormType.expense),
                            ),
                            _typeChip(
                              label: 'Khoản thu',
                              selected: transactionType == TransactionFormType.income,
                              onTap: () => _changeType(TransactionFormType.income),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ── Wallet
                      InkWell(
                        onTap: _showWalletSelector,
                        borderRadius: BorderRadius.circular(12),
                        child: _plainRow(
                          leading: const Icon(Icons.account_balance_wallet_outlined, size: 22, color: Color(0xFF8C919E)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  selectedWalletName.isEmpty ? '-' : selectedWalletName,
                                  style: const TextStyle(fontSize: 16, color: Color(0xFF181B23), fontWeight: FontWeight.w500),
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, size: 22, color: muted),
                            ],
                          ),
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
                                  selectedCategory.isEmpty ? '-' : selectedCategory,
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
                      if (attachments.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 76,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: attachments.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(
                                      attachments[index],
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
                                        final current =
                                            ref.read(transactionAttachmentsProvider);
                                        final next = current.toList(growable: true)
                                          ..removeAt(index);
                                        ref
                                            .read(transactionAttachmentsProvider.notifier)
                                            .state = List<Uint8List>.unmodifiable(next);
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
                      if (_existingAttachmentUrls.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 76,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _existingAttachmentUrls.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final imageUrl = _existingAttachmentUrls[index];
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      imageUrl,
                                      width: 76,
                                      height: 76,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        width: 76,
                                        height: 76,
                                        color: const Color(0xFFF1F3F8),
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.broken_image_outlined,
                                          color: Color(0xFF8C919E),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _existingAttachmentUrls.removeAt(
                                            index,
                                          );
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
                  onPressed: (isSubmitting || isMetaLoading) ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF22B45E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
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

