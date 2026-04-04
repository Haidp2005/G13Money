import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import 'language_service.dart';

class AuthService {
  AuthService._();

  static const List<_DefaultCategorySeed> _defaultCategorySeeds = [
    _DefaultCategorySeed(
      id: 'default-expense-food',
      name: 'Ăn uống',
      type: 'expense',
      iconKey: 'restaurant',
      colorHex: '#E07A5F',
    ),
    _DefaultCategorySeed(
      id: 'default-expense-transport',
      name: 'Di chuyển',
      type: 'expense',
      iconKey: 'directions_car',
      colorHex: '#3D5A80',
    ),
    _DefaultCategorySeed(
      id: 'default-expense-shopping',
      name: 'Mua sắm',
      type: 'expense',
      iconKey: 'shopping_bag',
      colorHex: '#9B5DE5',
    ),
    _DefaultCategorySeed(
      id: 'default-expense-home',
      name: 'Nhà ở',
      type: 'expense',
      iconKey: 'home',
      colorHex: '#81B29A',
    ),
    _DefaultCategorySeed(
      id: 'default-expense-entertainment',
      name: 'Giải trí',
      type: 'expense',
      iconKey: 'category',
      colorHex: '#FF6B6B',
    ),
    _DefaultCategorySeed(
      id: 'default-expense-health',
      name: 'Sức khỏe',
      type: 'expense',
      iconKey: 'health',
      colorHex: '#EF476F',
    ),
    _DefaultCategorySeed(
      id: 'default-expense-education',
      name: 'Giáo dục',
      type: 'expense',
      iconKey: 'education',
      colorHex: '#118AB2',
    ),
    _DefaultCategorySeed(
      id: 'default-expense-bills',
      name: 'Hóa đơn',
      type: 'expense',
      iconKey: 'bill',
      colorHex: '#073B4C',
    ),
    _DefaultCategorySeed(
      id: 'default-income-salary',
      name: 'Lương',
      type: 'income',
      iconKey: 'payments',
      colorHex: '#2DCC5A',
    ),
    _DefaultCategorySeed(
      id: 'default-income-bonus',
      name: 'Thưởng',
      type: 'income',
      iconKey: 'card_giftcard',
      colorHex: '#F09928',
    ),
    _DefaultCategorySeed(
      id: 'default-income-other',
      name: 'Thu nhập khác',
      type: 'income',
      iconKey: 'moving',
      colorHex: '#0D7377',
    ),
  ];

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static UserModel? _currentUser;

  static UserModel? get currentUser => _currentUser;
  static bool get isLoggedIn => _auth.currentUser != null;
  static String? get currentUserId => _auth.currentUser?.uid;

  static Future<UserModel?> restoreSession() async {
    final user = _auth.currentUser;
    if (user == null) {
      _currentUser = null;
      return null;
    }
    _currentUser = await _upsertAndReadUserModel(user);
    return _currentUser;
  }

  static Future<UserModel> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _currentUser = await _upsertAndReadUserModel(credential.user!);
      return _currentUser!;
    } on FirebaseAuthException catch (e) {
      throw Exception(_authErrorMessage(e.code));
    }
  }

  static Future<UserModel> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    User? createdUser;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw Exception(
          LanguageService.tr(
            vi: 'Không thể tạo tài khoản. Vui lòng thử lại',
            en: 'Could not create account. Please try again',
          ),
        );
      }
      createdUser = user;

      final normalizedName = fullName.trim();
      final normalizedPhone = phone.trim();
      if (normalizedName.isNotEmpty) {
        await user.updateDisplayName(normalizedName);
      }

      await _createInitialUserDocs(
        user: user,
        fullName: normalizedName,
        phone: normalizedPhone,
      );

      _currentUser = await _upsertAndReadUserModel(user);

      return _currentUser!;
    } on FirebaseAuthException catch (e) {
      throw Exception(_authErrorMessage(e.code));
    } catch (e) {
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {
          // Ignore cleanup errors and still surface the original failure.
        }
        await _auth.signOut();
      }
      throw Exception(
        LanguageService.tr(
          vi: 'Tạo người dùng thất bại. Vui lòng thử lại',
          en: 'Failed to create user profile. Please try again',
        ),
      );
    }
  }

  static Future<void> _createInitialUserDocs({
    required User user,
    required String fullName,
    required String phone,
  }) async {
    final normalizedName = fullName.trim().isEmpty
        ? _displayNameFromEmail(user.email)
        : fullName.trim();
    final normalizedPhone = phone.trim();

    final userDoc = _db.collection('users').doc(user.uid);
    final profileDoc = userDoc.collection('settings').doc('profile');
    final preferencesDoc = userDoc.collection('settings').doc('preferences');
    final categoriesCollection = userDoc.collection('categories');

    final batch = _db.batch();
    batch.set(userDoc, {
      'fullName': normalizedName,
      'email': (user.email ?? '').trim().toLowerCase(),
      'phone': normalizedPhone,
      'avatarInitials': _buildInitials(normalizedName),
      'joinedAt': Timestamp.fromDate(DateTime.now()),
      'currency': 'VND',
      'locale': 'vi',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(profileDoc, {
      'fullName': normalizedName,
      'phone': normalizedPhone,
      'avatarInitials': _buildInitials(normalizedName),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(preferencesDoc, {
      'transactionAlerts': true,
      'language': 'vi',
      'themeMode': 'system',
      'budgetAlerts': true,
      'budgetAlertThresholdPercent': 80,
      'dailyReminder': false,
      'billReminder': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    for (final item in _defaultCategorySeeds) {
      batch.set(categoriesCollection.doc(item.id), {
        'name': item.name,
        'type': item.type,
        'iconKey': item.iconKey,
        'colorHex': item.colorHex,
        'isDefault': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  static Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
  }

  static Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
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
    if (newPass.length < 6) {
      throw Exception(
        LanguageService.tr(
          vi: 'Mật khẩu mới phải có ít nhất 6 ký tự',
          en: 'New password must be at least 6 characters',
        ),
      );
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPass,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPass);
    } on FirebaseAuthException catch (e) {
      throw Exception(_authErrorMessage(e.code));
    }
  }

  static Future<void> updateCurrentUserProfile({
    required String fullName,
    required String phone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception(LanguageService.tr(vi: 'Bạn chưa đăng nhập', en: 'You are not logged in'));
    }

    final normalizedName = fullName.trim();
    final normalizedPhone = phone.trim();
    final initials = _buildInitials(normalizedName);

    final userDoc = _db.collection('users').doc(user.uid);
    final profileDoc = userDoc.collection('settings').doc('profile');

    final batch = _db.batch();
    batch.set(
      userDoc,
      {
        'fullName': normalizedName,
        'phone': normalizedPhone,
        'avatarInitials': initials,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(
      profileDoc,
      {
        'fullName': normalizedName,
        'phone': normalizedPhone,
        'avatarInitials': initials,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();

    await user.updateDisplayName(normalizedName);

    _currentUser = (_currentUser ?? _fallbackModel(user)).copyWith(
      fullName: normalizedName,
      phone: normalizedPhone,
      avatarInitials: initials,
    );
  }

  static Future<UserModel> _upsertAndReadUserModel(User user) async {
    final docRef = _db.collection('users').doc(user.uid);
    final snapshot = await docRef.get();
    final now = DateTime.now();

    if (!snapshot.exists) {
      final fullName = (user.displayName ?? '').trim().isEmpty
          ? _displayNameFromEmail(user.email)
          : user.displayName!.trim();
      final model = UserModel(
        id: user.uid,
        fullName: fullName,
        email: (user.email ?? '').trim().toLowerCase(),
        phone: '',
        avatarInitials: _buildInitials(fullName),
        joinedDate: now,
      );

      await docRef.set({
        'fullName': model.fullName,
        'email': model.email,
        'phone': model.phone,
        'avatarInitials': model.avatarInitials,
        'joinedAt': Timestamp.fromDate(model.joinedDate),
        'currency': 'VND',
        'locale': 'vi',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return model;
    }

    final data = snapshot.data()!;
    final fullName = (data['fullName'] as String?)?.trim();
    final email = (data['email'] as String?)?.trim().toLowerCase();
    final phone = (data['phone'] as String?)?.trim();
    final avatarInitials = (data['avatarInitials'] as String?)?.trim();
    final joinedAt = _asDateTime(data['joinedAt']) ?? now;

    return UserModel(
      id: user.uid,
      fullName: (fullName == null || fullName.isEmpty)
          ? _displayNameFromEmail(user.email)
          : fullName,
      email: (email == null || email.isEmpty)
          ? (user.email ?? '').trim().toLowerCase()
          : email,
      phone: phone ?? '',
      avatarInitials: (avatarInitials == null || avatarInitials.isEmpty)
          ? _buildInitials(fullName ?? _displayNameFromEmail(user.email))
          : avatarInitials,
      joinedDate: joinedAt,
    );
  }

  static UserModel _fallbackModel(User user) {
    final fullName = _displayNameFromEmail(user.email);
    return UserModel(
      id: user.uid,
      fullName: fullName,
      email: (user.email ?? '').trim().toLowerCase(),
      phone: '',
      avatarInitials: _buildInitials(fullName),
      joinedDate: DateTime.now(),
    );
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  static String _displayNameFromEmail(String? email) {
    final raw = (email ?? '').split('@').first.replaceAll('.', ' ').trim();
    if (raw.isEmpty) {
      return 'User';
    }
    final words = raw
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
    return words;
  }

  static String _authErrorMessage(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return LanguageService.tr(
          vi: 'Email hoặc mật khẩu không chính xác',
          en: 'Incorrect email or password',
        );
      case 'user-disabled':
        return LanguageService.tr(
          vi: 'Tài khoản đã bị vô hiệu hóa',
          en: 'This account has been disabled',
        );
      case 'too-many-requests':
        return LanguageService.tr(
          vi: 'Bạn thử lại sau ít phút',
          en: 'Too many attempts, try again later',
        );
      case 'email-already-in-use':
        return LanguageService.tr(
          vi: 'Email đã được sử dụng',
          en: 'This email is already in use',
        );
      case 'weak-password':
        return LanguageService.tr(
          vi: 'Mật khẩu quá yếu, vui lòng chọn mật khẩu mạnh hơn',
          en: 'Password is too weak, please choose a stronger password',
        );
      case 'invalid-email':
        return LanguageService.tr(
          vi: 'Địa chỉ email không hợp lệ',
          en: 'Invalid email address',
        );
      case 'requires-recent-login':
        return LanguageService.tr(
          vi: 'Vui lòng đăng nhập lại để tiếp tục',
          en: 'Please sign in again to continue',
        );
      default:
        return LanguageService.tr(
          vi: 'Có lỗi xác thực. Vui lòng thử lại',
          en: 'Authentication error. Please try again',
        );
    }
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

class _DefaultCategorySeed {
  final String id;
  final String name;
  final String type;
  final String iconKey;
  final String colorHex;

  const _DefaultCategorySeed({
    required this.id,
    required this.name,
    required this.type,
    required this.iconKey,
    required this.colorHex,
  });
}
