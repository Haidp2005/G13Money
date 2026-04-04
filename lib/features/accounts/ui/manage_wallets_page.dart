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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: LanguageService.tr(vi: 'Tên ví/tài khoản', en: 'Wallet/account name'),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? LanguageService.tr(vi: 'Vui lòng nhập tên', en: 'Please enter name')
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: InputDecoration(
                  labelText: LanguageService.tr(vi: 'Loại', en: 'Type'),
                ),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'bank', child: Text('Bank')),
                  DropdownMenuItem(value: 'ewallet', child: Text('E-wallet')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    ref.read(accountFormTypeProvider.notifier).state = v;
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _balanceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Số dư'),
                validator: (v) {
                  final parsed = double.tryParse((v ?? '').replaceAll(',', '').trim());
                  if (parsed == null || parsed < 0) {
                    return LanguageService.tr(vi: 'Số dư không hợp lệ', en: 'Invalid balance');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(LanguageService.tr(vi: 'Lưu', en: 'Save')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
