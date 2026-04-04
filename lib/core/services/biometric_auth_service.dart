import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  BiometricAuthService._();

  static final FlutterSecureStorage _storage = FlutterSecureStorage();
  static final LocalAuthentication _localAuth = LocalAuthentication();

  static const String _emailKey = 'bio_login_email';
  static const String _passwordKey = 'bio_login_password';

  static Future<bool> isBiometricSupported() async {
    final canCheckBiometrics = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();
    return canCheckBiometrics && isSupported;
  }

  static Future<bool> hasSavedCredentials() async {
    final email = await _storage.read(key: _emailKey);
    final password = await _storage.read(key: _passwordKey);
    return (email?.trim().isNotEmpty ?? false) &&
        (password?.trim().isNotEmpty ?? false);
  }

  static Future<String?> getSavedEmail() async {
    return await _storage.read(key: _emailKey);
  }

  static Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    await _storage.write(key: _emailKey, value: email.trim());
    await _storage.write(key: _passwordKey, value: password);
  }

  static Future<void> clearCredentials() async {
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passwordKey);
  }

  static Future<({String email, String password})?> authenticateAndGetCredentials() async {
    final didAuthenticate = await _localAuth.authenticate(
      localizedReason: 'Xac thuc de dang nhap bang sinh trac hoc',
      options: const AuthenticationOptions(
        biometricOnly: false,
        stickyAuth: true,
        sensitiveTransaction: true,
      ),
    );

    if (!didAuthenticate) return null;

    final email = await _storage.read(key: _emailKey);
    final password = await _storage.read(key: _passwordKey);
    if (email == null || password == null) return null;
    if (email.trim().isEmpty || password.trim().isEmpty) return null;

    return (email: email, password: password);
  }
}
