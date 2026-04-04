import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/supabase_storage_service.dart';
import '../state/edit_profile_state.dart';
import '../state/profile_state.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  final ImagePicker _imagePicker = ImagePicker();

  XFile? _selectedAvatar;
  String _currentAvatarUrl = '';

  @override
  void initState() {
    super.initState();
    final user = AuthService.currentUser;
    _nameCtrl = TextEditingController(text: user?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _currentAvatarUrl = user?.avatarUrl ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(editProfileSavingProvider.notifier).state = true;

    try {
      String? nextAvatarUrl;
      if (_selectedAvatar != null) {
        final uid = AuthService.currentUserId;
        if (uid == null) {
          throw Exception('Bạn chưa đăng nhập');
        }
        final bytes = await _selectedAvatar!.readAsBytes();
        nextAvatarUrl = await SupabaseStorageService.uploadAvatar(
          uid: uid,
          bytes: bytes,
        );
      }

      await AuthService.updateCurrentUserProfile(
        fullName: _nameCtrl.text,
        phone: _phoneCtrl.text,
        avatarUrl: nextAvatarUrl,
      );

      ref.read(profileRefreshTickProvider.notifier).state++;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LanguageService.tr(
              vi: 'Đã cập nhật thông tin thành công!',
              en: 'Profile updated successfully!',
            ),
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      ref.read(editProfileSavingProvider.notifier).state = false;
    }
  }

  Future<void> _pickAvatar() async {
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
                  title: Text(
                    LanguageService.tr(vi: 'Chụp ảnh', en: 'Take photo'),
                  ),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text(
                    LanguageService.tr(
                      vi: 'Chọn từ thư viện',
                      en: 'Choose from gallery',
                    ),
                  ),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    final file = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    setState(() {
      _selectedAvatar = file;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(editProfileSavingProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          LanguageService.tr(vi: 'Chỉnh sửa thông tin', en: 'Edit profile'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar Section
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: _selectedAvatar != null
                          ? Image.file(
                            File(_selectedAvatar!.path),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _avatarInitials(scheme),
                              )
                            : (_currentAvatarUrl.trim().isNotEmpty
                                ? Image.network(
                                    _currentAvatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        _avatarInitials(scheme),
                                  )
                                : _avatarInitials(scheme)),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickAvatar,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Inputs
              _buildInput(
                controller: _nameCtrl,
                label: LanguageService.tr(vi: 'Họ và tên', en: 'Full name'),
                icon: Icons.person_outline,
                validator: (v) =>
                    (v == null || v.isEmpty)
                        ? LanguageService.tr(vi: 'Không được để trống', en: 'Required')
                        : null,
              ),
              const SizedBox(height: 20),
              _buildInput(
                controller: _phoneCtrl,
                label: LanguageService.tr(vi: 'Số điện thoại', en: 'Phone number'),
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.isEmpty)
                        ? LanguageService.tr(vi: 'Không được để trống', en: 'Required')
                        : null,
              ),
              const SizedBox(height: 40),

              // Save Button
              ElevatedButton(
                onPressed: isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      LanguageService.tr(vi: 'Lưu thay đổi', en: 'Save changes'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarInitials(ColorScheme scheme) {
    return Center(
      child: Text(
        AuthService.currentUser?.avatarInitials ?? '',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: scheme.primary,
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: scheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
    );
  }
}
