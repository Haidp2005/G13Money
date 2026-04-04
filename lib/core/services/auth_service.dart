import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import 'language_service.dart';

class AuthService {
  AuthService._();

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
