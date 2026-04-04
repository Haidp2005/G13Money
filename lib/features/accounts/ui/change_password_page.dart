import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/language_service.dart';
import '../state/change_password_state.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  @override
  void dispose() {
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(changePasswordSavingProvider.notifier).state = true;

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      await AuthService.changePassword(
        oldPassword: _oldPasswordCtrl.text,
        newPassword: _newPasswordCtrl.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LanguageService.tr(
              vi: 'Đổi mật khẩu thành công',
              en: 'Password changed successfully',
            ),
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      ref.read(changePasswordSavingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(changePasswordSavingProvider);
    final obscureOld = ref.watch(changePasswordObscureOldProvider);
    final obscureNew = ref.watch(changePasswordObscureNewProvider);
    final obscureConfirm = ref.watch(changePasswordObscureConfirmProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(LanguageService.tr(vi: 'Đổi mật khẩu', en: 'Change password')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildPasswordField(
                controller: _oldPasswordCtrl,
                label: LanguageService.tr(vi: 'Mật khẩu cũ', en: 'Current password'),
                icon: Icons.lock_outline,
                obscure: obscureOld,
                onToggleObscure: () =>
                    ref.read(changePasswordObscureOldProvider.notifier).state = !obscureOld,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return LanguageService.tr(
                      vi: 'Vui lòng nhập mật khẩu cũ',
                      en: 'Please enter current password',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _newPasswordCtrl,
                label: LanguageService.tr(vi: 'Mật khẩu mới', en: 'New password'),
                icon: Icons.lock_reset,
                obscure: obscureNew,
                onToggleObscure: () =>
                    ref.read(changePasswordObscureNewProvider.notifier).state = !obscureNew,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return LanguageService.tr(
                      vi: 'Vui lòng nhập mật khẩu mới',
                      en: 'Please enter new password',
                    );
                  }
                  if (v.trim().length < 6) {
                    return LanguageService.tr(vi: 'Tối thiểu 6 ký tự', en: 'Minimum 6 characters');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _confirmPasswordCtrl,
                label: LanguageService.tr(
                  vi: 'Xác nhận mật khẩu mới',
                  en: 'Confirm new password',
                ),
                icon: Icons.verified_user_outlined,
                obscure: obscureConfirm,
                onToggleObscure: () =>
                  ref.read(changePasswordObscureConfirmProvider.notifier).state =
                    !obscureConfirm,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return LanguageService.tr(
                      vi: 'Vui lòng xác nhận mật khẩu mới',
                      en: 'Please confirm new password',
                    );
                  }
                  if (v.trim() != _newPasswordCtrl.text.trim()) {
                    return LanguageService.tr(
                      vi: 'Mật khẩu xác nhận không khớp',
                      en: 'Password confirmation does not match',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          LanguageService.tr(
                            vi: 'Lưu mật khẩu mới',
                            en: 'Save new password',
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggleObscure,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(icon),
        suffixIcon: IconButton(
          onPressed: onToggleObscure,
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
        ),
      ),
    );
  }
}
