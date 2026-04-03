import '../models/user_model.dart';
import 'language_service.dart';

/// Mock authentication service – thay thế bằng API thật sau.
class AuthService {
  static UserModel? _currentUser;
  static String _currentPassword = '123456';

  static UserModel? get currentUser => _currentUser;
  static bool get isLoggedIn => _currentUser != null;

  /// Trả về [UserModel] nếu thành công, ném [Exception] nếu sai thông tin.
  static Future<UserModel> login(String email, String password) async {
    // Giả lập độ trễ mạng
    await Future.delayed(const Duration(milliseconds: 1200));

    // Mock credentials
    if (email.trim().toLowerCase() == 'admin@g13.com' &&
      password == _currentPassword) {
      _currentUser = UserModel(
        id: 'usr_001',
        fullName: 'Nguyễn Văn An',
        email: email.trim().toLowerCase(),
        phone: '0987 654 321',
        avatarInitials: 'NA',
        joinedDate: DateTime(2025, 3, 1),
      );
      return _currentUser!;
    }

    throw Exception(
      LanguageService.tr(
        vi: 'Email hoặc mật khẩu không chính xác',
        en: 'Incorrect email or password',
      ),
    );
  }

  static void logout() {
    _currentUser = null;
  }

  static Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      throw Exception(LanguageService.tr(vi: 'Bạn chưa đăng nhập', en: 'You are not logged in'));
    }

    final oldPass = oldPassword.trim();
    final newPass = newPassword.trim();

    if (oldPass.isEmpty || newPass.isEmpty) {
      throw Exception(
        LanguageService.tr(
          vi: 'Vui lòng nhập đầy đủ thông tin',
          en: 'Please fill in all required fields',
        ),
      );
    }
    if (oldPass != _currentPassword) {
      throw Exception(LanguageService.tr(vi: 'Mật khẩu cũ không đúng', en: 'Current password is incorrect'));
    }
    if (newPass.length < 6) {
      throw Exception(
        LanguageService.tr(
          vi: 'Mật khẩu mới phải có ít nhất 6 ký tự',
          en: 'New password must be at least 6 characters',
        ),
      );
    }
    if (newPass == _currentPassword) {
      throw Exception(
        LanguageService.tr(
          vi: 'Mật khẩu mới phải khác mật khẩu cũ',
          en: 'New password must be different from current password',
        ),
      );
    }

    _currentPassword = newPass;
  }

  static Future<void> updateCurrentUserProfile({
    required String fullName,
    required String phone,
  }) async {
    final current = _currentUser;
    if (current == null) {
      throw Exception(LanguageService.tr(vi: 'Bạn chưa đăng nhập', en: 'You are not logged in'));
    }

    final normalizedName = fullName.trim();
    final normalizedPhone = phone.trim();

    _currentUser = current.copyWith(
      fullName: normalizedName,
      phone: normalizedPhone,
      avatarInitials: _buildInitials(normalizedName),
    );
  }

  static String _buildInitials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();

    final first = parts.first[0];
    final last = parts.last[0];
    return (first + last).toUpperCase();
  }
}
