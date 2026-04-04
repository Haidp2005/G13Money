import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/language_service.dart';
import '../models/account.dart';
import '../state/manage_wallets_state.dart';

class ManageWalletsPage extends ConsumerWidget {
  const ManageWalletsPage({super.key});

  Future<void> _openAccountForm(BuildContext context, WidgetRef ref, [Account? account]) async {
    final result = await showModalBottomSheet<Account>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AccountFormSheet(initial: account),
    );

    if (result == null || !context.mounted) return;
    await ref.read(walletsProvider.notifier).upsert(result);
  }

  Future<void> _deleteAccount(WidgetRef ref, Account account) async {
    await ref.read(walletsProvider.notifier).delete(account.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsState = ref.watch(walletsProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(LanguageService.tr(vi: 'Ví và tài khoản', en: 'Wallets and accounts')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAccountForm(context, ref),
        icon: const Icon(Icons.add),
        label: Text(LanguageService.tr(vi: 'Thêm ví', en: 'Add wallet')),
      ),
      body: walletsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 42),
                        const SizedBox(height: 10),
                        Text(
                          LanguageService.tr(
                            vi: 'Không tải được danh sách ví.',
                            en: 'Could not load wallets list.',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          error.toString().replaceFirst('Exception: ', ''),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: scheme.outline),
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: () => ref.read(walletsProvider.notifier).refresh(),
                          icon: const Icon(Icons.refresh),
                          label: Text(LanguageService.tr(vi: 'Thử lại', en: 'Retry')),
                        ),
                      ],
                    ),
                  ),
                )
        ,
        data: (accounts) => accounts.isEmpty
              ? Center(
                  child: Text(
                    LanguageService.tr(
                      vi: 'Chưa có ví nào. Hãy tạo ví đầu tiên.',
                      en: 'No wallet yet. Create your first wallet.',
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    return ListTile(
                      tileColor: scheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: scheme.primaryContainer,
                        child: Icon(_iconForType(account.type), color: scheme.primary),
                      ),
                      title: Text(account.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(_typeLabel(account.type)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currency(account.balance),
                            style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _openAccountForm(context, ref, account);
                              } else if (value == 'delete') {
                                _deleteAccount(ref, account);
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
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemCount: accounts.length,
                ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'bank':
        return Icons.account_balance_outlined;
      case 'ewallet':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.payments_outlined;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'bank':
        return LanguageService.tr(vi: 'Ngân hàng', en: 'Bank');
      case 'ewallet':
        return LanguageService.tr(vi: 'Ví điện tử', en: 'E-wallet');
      default:
        return LanguageService.tr(vi: 'Tiền mặt', en: 'Cash');
    }
  }

  String _currency(double value) {
    final s = value.toStringAsFixed(0);
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return '${b.toString()} đ';
  }
}

class _AccountFormSheet extends ConsumerStatefulWidget {
  final Account? initial;
  const _AccountFormSheet({this.initial});

  @override
  ConsumerState<_AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends ConsumerState<_AccountFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _balanceCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial?.name ?? '');
    _balanceCtrl = TextEditingController(
      text: widget.initial == null ? '' : widget.initial!.balance.toStringAsFixed(0),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(accountFormTypeProvider.notifier).state =
          widget.initial?.type ?? 'cash';
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final balance = double.parse(_balanceCtrl.text.replaceAll(',', '').trim());
    final type = ref.read(accountFormTypeProvider);

    final model = Account(
      id: widget.initial?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      type: type,
      balance: balance,
      colorHex: widget.initial?.colorHex ?? '#0D7377',
      isArchived: false,
    );

    Navigator.pop(context, model);
  }

  @override
  Widget build(BuildContext context) {
    final selectedType = ref.watch(accountFormTypeProvider);
    final isEdit = widget.initial != null;
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      LanguageService.tr(
                        vi: isEdit ? 'Sửa thông tin ví' : 'Thêm ví mới', 
                        en: isEdit ? 'Edit wallet' : 'Add new wallet'
                      ),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF171A21),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3F8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF5A5F6E)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Name Input
                Text(
                  LanguageService.tr(vi: 'Tên ví/tài khoản', en: 'Wallet/account name'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF5A5F6E)),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8EAF0)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextFormField(
                    controller: _nameCtrl,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF171A21)),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: LanguageService.tr(vi: 'Ví dụ: Tiền mặt, VIB, Momo...', en: 'Eg: Cash, Bank, PayPal...'),
                      hintStyle: const TextStyle(color: Color(0xFF8C919E), fontWeight: FontWeight.normal),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? LanguageService.tr(vi: 'Vui lòng nhập tên', en: 'Please enter name')
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Type Selector
                Text(
                  LanguageService.tr(vi: 'Loại tài khoản', en: 'Account type'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF5A5F6E)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildTypeChip('cash', Icons.payments_outlined, LanguageService.tr(vi: 'Tiền mặt', en: 'Cash'), selectedType),
                    const SizedBox(width: 8),
                    _buildTypeChip('bank', Icons.account_balance_outlined, LanguageService.tr(vi: 'Ngân hàng', en: 'Bank'), selectedType),
                    const SizedBox(width: 8),
                    _buildTypeChip('ewallet', Icons.account_balance_wallet_outlined, LanguageService.tr(vi: 'Ví điện tử', en: 'E-Wallet'), selectedType),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Balance Input
                Text(
                  LanguageService.tr(vi: 'Số dư ban đầu', en: 'Initial balance'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF5A5F6E)),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8EAF0)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Text(
                        'đ',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF22B45E)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _balanceCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF22B45E)),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '0',
                            hintStyle: TextStyle(color: const Color(0xFF22B45E).withValues(alpha: 0.5)),
                          ),
                          validator: (v) {
                            final parsed = double.tryParse((v ?? '').replaceAll(',', '').trim());
                            if (parsed == null || parsed < 0) {
                              return LanguageService.tr(vi: 'Số dư không hợp lệ', en: 'Invalid balance');
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF22B45E),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      LanguageService.tr(vi: 'Lưu ví', en: 'Save wallet'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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

  Widget _buildTypeChip(String type, IconData icon, String label, String selectedType) {
    final isSelected = type == selectedType;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(accountFormTypeProvider.notifier).state = type,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF22B45E).withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF22B45E) : const Color(0xFFE8EAF0),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? const Color(0xFF22B45E) : const Color(0xFF8C919E),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF22B45E) : const Color(0xFF5A5F6E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
