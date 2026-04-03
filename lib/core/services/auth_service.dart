import '../models/user_model.dart';

/// Mock authentication service – thay thế bằng API thật sau.
class AuthService {
  static UserModel? _currentUser;

  static UserModel? get currentUser => _currentUser;
  static bool get isLoggedIn => _currentUser != null;

  /// Trả về [UserModel] nếu thành công, ném [Exception] nếu sai thông tin.
  static Future<UserModel> login(String email, String password) async {
    // Giả lập độ trễ mạng
    await Future.delayed(const Duration(milliseconds: 1200));

    // Mock credentials
    if (email.trim().toLowerCase() == 'admin@g13.com' &&
        password == '123456') {
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

    throw Exception('Email hoặc mật khẩu không chính xác');
  }

  static void logout() {
    _currentUser = null;
  }
}
