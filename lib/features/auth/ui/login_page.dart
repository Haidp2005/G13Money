import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/biometric_auth_service.dart';
import '../../../core/services/language_service.dart';
import '../../../app/routes.dart';
import '../state/login_state.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  // Quick-login (saved session) state
  final _quickPassCtrl = TextEditingController();
  String? _savedEmail;
  bool _hasSavedSession = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool _biometricAvailable = false;
  bool _biometricLoading = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _animCtrl.forward();
    _initSessionState();
  }

  Future<void> _initSessionState() async {
    final isSupported = await BiometricAuthService.isBiometricSupported();
    final hasCredentials = await BiometricAuthService.hasSavedCredentials();
    final email = await BiometricAuthService.getSavedEmail();
    if (!mounted) return;
    setState(() {
      _hasSavedSession = hasCredentials;
      _savedEmail = email;
      _biometricAvailable = isSupported && hasCredentials;
    });
    // Auto-enter quick-login mode if there's a saved session
    if (hasCredentials) {
      ref.read(isQuickLoginModeProvider.notifier).state = true;
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _quickPassCtrl.dispose();
    super.dispose();
  }

  // ── Quick login with password ──────────────────────────────────────────────

  Future<void> _quickLoginWithPassword() async {
    FocusScope.of(context).unfocus();
    final pass = _quickPassCtrl.text;
    if (pass.isEmpty) {
      ref.read(loginErrorProvider.notifier).state = LanguageService.tr(
        vi: 'Vui lòng nhập mật khẩu',
        en: 'Please enter password',
      );
      return;
    }
    if (_savedEmail == null) return;

    ref.read(loginLoadingProvider.notifier).state = true;
    ref.read(loginErrorProvider.notifier).state = null;

    try {
      await AuthService.login(_savedEmail!, pass);
      // Update saved password if login succeeds
      await BiometricAuthService.saveCredentials(
        email: _savedEmail!,
        password: pass,
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ref.read(loginErrorProvider.notifier).state =
            e.toString().replaceFirst('Exception: ', '');
      }
    } finally {
      if (mounted) {
        ref.read(loginLoadingProvider.notifier).state = false;
      }
    }
  }

  // ── Full login submit ──────────────────────────────────────────────────────

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final isRegisterMode = ref.read(isRegisterModeProvider);

    ref.read(loginLoadingProvider.notifier).state = true;
    ref.read(loginErrorProvider.notifier).state = null;

    try {
      if (isRegisterMode) {
        await AuthService.register(
          fullName: _fullNameCtrl.text,
          phone: _phoneCtrl.text,
          email: _emailCtrl.text,
          password: _passCtrl.text,
        );
      } else {
        await AuthService.login(_emailCtrl.text, _passCtrl.text);
      }
      await BiometricAuthService.saveCredentials(
        email: _emailCtrl.text,
        password: _passCtrl.text,
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ref.read(loginErrorProvider.notifier).state =
            e.toString().replaceFirst('Exception: ', '');
      }
    } finally {
      if (mounted) {
        ref.read(loginLoadingProvider.notifier).state = false;
      }
    }
  }

  Future<void> _signInWithBiometric() async {
    if (_biometricLoading) return;

    setState(() {
      _biometricLoading = true;
    });
    ref.read(loginErrorProvider.notifier).state = null;

    try {
      final credentials =
          await BiometricAuthService.authenticateAndGetCredentials();
      if (credentials == null) {
        if (mounted) {
          ref.read(loginErrorProvider.notifier).state =
              LanguageService.tr(
                vi: 'Không thể xác thực sinh trắc học',
                en: 'Biometric authentication failed',
              );
        }
        return;
      }

      await AuthService.login(credentials.email, credentials.password);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } catch (e) {
      if (mounted) {
        ref.read(loginErrorProvider.notifier).state =
            e.toString().replaceFirst('Exception: ', '');
      }
    } finally {
      if (mounted) {
        setState(() {
          _biometricLoading = false;
        });
      }
    }
  }

  void _switchToFullLogin() {
    ref.read(isQuickLoginModeProvider.notifier).state = false;
    ref.read(loginErrorProvider.notifier).state = null;
    _quickPassCtrl.clear();
    // Restart animation
    _animCtrl.reset();
    _animCtrl.forward();
  }

  void _switchBackToQuickLogin() {
    ref.read(isQuickLoginModeProvider.notifier).state = true;
    ref.read(loginErrorProvider.notifier).state = null;
    _animCtrl.reset();
    _animCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final obscure = ref.watch(loginObscureProvider);
    final loading = ref.watch(loginLoadingProvider);
    final errorMsg = ref.watch(loginErrorProvider);
    final isRegisterMode = ref.watch(isRegisterModeProvider);
    final isQuickLogin = ref.watch(isQuickLoginModeProvider);
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        children: [
          // ── Gradient background ────────────────────────────────
          _Background(scheme: scheme, size: size),

          // ── Scrollable form ────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _Logo(scheme: scheme),
                          const SizedBox(height: 36),

                          // Show Quick Login or Full Login based on mode
                          if (_hasSavedSession && isQuickLogin)
                            _QuickLoginCard(
                              savedEmail: _savedEmail ?? '',
                              passCtrl: _quickPassCtrl,
                              obscure: obscure,
                              loading: loading,
                              biometricLoading: _biometricLoading,
                              biometricAvailable: _biometricAvailable,
                              errorMsg: errorMsg,
                              scheme: scheme,
                              onToggleObscure: () {
                                ref.read(loginObscureProvider.notifier).state =
                                    !obscure;
                              },
                              onSubmit: _quickLoginWithPassword,
                              onBiometricLogin: _signInWithBiometric,
                              onSwitchToFullLogin: _switchToFullLogin,
                            )
                          else
                            _FormCard(
                              formKey: _formKey,
                              fullNameCtrl: _fullNameCtrl,
                              phoneCtrl: _phoneCtrl,
                              emailCtrl: _emailCtrl,
                              passCtrl: _passCtrl,
                              confirmPassCtrl: _confirmPassCtrl,
                              obscure: obscure,
                              loading: loading,
                              biometricLoading: _biometricLoading,
                              errorMsg: errorMsg,
                              isRegisterMode: isRegisterMode,
                              biometricAvailable: _biometricAvailable &&
                                  !isQuickLogin,
                              hasSavedSession: _hasSavedSession,
                              onToggleObscure: () {
                                ref.read(loginObscureProvider.notifier).state =
                                    !obscure;
                              },
                              onSwitchMode: () {
                                ref
                                    .read(isRegisterModeProvider.notifier)
                                    .state = !isRegisterMode;
                                ref.read(loginErrorProvider.notifier).state =
                                    null;
                              },
                              onBiometricLogin: _signInWithBiometric,
                              onSubmit: _submit,
                              onBackToQuickLogin:
                                  _hasSavedSession
                                      ? _switchBackToQuickLogin
                                      : null,
                              scheme: scheme,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Background ───────────────────────────────────────────────────────────────

class _Background extends StatelessWidget {
  final ColorScheme scheme;
  final Size size;
  const _Background({required this.scheme, required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [scheme.primary, scheme.tertiary, scheme.secondary],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        // Decorative circles
        Positioned(
          top: -size.width * 0.3,
          right: -size.width * 0.2,
          child: _Circle(
            size.width * 0.75,
            Colors.white.withValues(alpha: 0.07),
          ),
        ),
        Positioned(
          bottom: -size.height * 0.15,
          left: -size.width * 0.25,
          child: _Circle(
            size.width * 0.8,
            Colors.white.withValues(alpha: 0.06),
          ),
        ),
        Positioned(
          top: size.height * 0.25,
          left: -size.width * 0.1,
          child: _Circle(
            size.width * 0.4,
            Colors.white.withValues(alpha: 0.04),
          ),
        ),
      ],
    );
  }
}

class _Circle extends StatelessWidget {
  final double diameter;
  final Color color;
  const _Circle(this.diameter, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

// ── Logo / Title ─────────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  final ColorScheme scheme;
  const _Logo({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'G13 Money',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          LanguageService.tr(
            vi: 'Quản lý tài chính thông minh',
            en: 'Smart personal finance management',
          ),
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.8),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ── Quick Login Card ──────────────────────────────────────────────────────────

class _QuickLoginCard extends StatelessWidget {
  final String savedEmail;
  final TextEditingController passCtrl;
  final bool obscure;
  final bool loading;
  final bool biometricLoading;
  final bool biometricAvailable;
  final String? errorMsg;
  final ColorScheme scheme;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final VoidCallback onBiometricLogin;
  final VoidCallback onSwitchToFullLogin;

  const _QuickLoginCard({
    required this.savedEmail,
    required this.passCtrl,
    required this.obscure,
    required this.loading,
    required this.biometricLoading,
    required this.biometricAvailable,
    required this.errorMsg,
    required this.scheme,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.onBiometricLogin,
    required this.onSwitchToFullLogin,
  });

  String _avatarLetter() {
    if (savedEmail.isEmpty) return '?';
    return savedEmail[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────
          Text(
            LanguageService.tr(
              vi: 'Chào mừng trở lại!',
              en: 'Welcome back!',
            ),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            LanguageService.tr(
              vi: 'Xác nhận để tiếp tục phiên làm việc.',
              en: 'Verify to continue your session.',
            ),
            style: TextStyle(fontSize: 13, color: scheme.outline),
          ),
          const SizedBox(height: 24),

          // ── User avatar pill ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                // Avatar circle
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [scheme.primary, scheme.tertiary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _avatarLetter(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LanguageService.tr(
                          vi: 'Tài khoản đã lưu',
                          en: 'Saved account',
                        ),
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.outline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        savedEmail,
                        style: TextStyle(
                          fontSize: 14,
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.check_circle_rounded,
                  color: scheme.primary,
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Biometric button (primary CTA if available) ──────────
          if (biometricAvailable) ...[
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: (loading || biometricLoading)
                    ? null
                    : onBiometricLogin,
                icon: biometricLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.fingerprint, size: 22),
                label: Text(
                  LanguageService.tr(
                    vi: 'Đăng nhập bằng sinh trắc học',
                    en: 'Sign in with biometrics',
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Divider
            Row(
              children: [
                Expanded(
                  child: Divider(color: scheme.outline.withValues(alpha: 0.25)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    LanguageService.tr(vi: 'hoặc', en: 'or'),
                    style: TextStyle(fontSize: 12, color: scheme.outline),
                  ),
                ),
                Expanded(
                  child: Divider(color: scheme.outline.withValues(alpha: 0.25)),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // ── Password field ───────────────────────────────────────
          TextFormField(
            controller: passCtrl,
            obscureText: obscure,
            keyboardType: TextInputType.visiblePassword,
            style: const TextStyle(fontSize: 15),
            onFieldSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              labelText: LanguageService.tr(vi: 'Mật khẩu', en: 'Password'),
              hintText: '••••••',
              prefixIcon: Icon(Icons.lock_outline, size: 20, color: scheme.primary),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: scheme.outline,
                  size: 20,
                ),
                onPressed: onToggleObscure,
              ),
              filled: true,
              fillColor: scheme.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: scheme.outline.withValues(alpha: 0.25)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: scheme.primary, width: 1.8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Error message ────────────────────────────────────────
          if (errorMsg != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: scheme.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMsg!,
                      style: TextStyle(
                        color: scheme.onErrorContainer,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── Confirm button ───────────────────────────────────────
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: loading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    biometricAvailable ? scheme.secondary : scheme.primary,
                foregroundColor:
                    biometricAvailable ? scheme.onSecondary : scheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      LanguageService.tr(
                        vi: 'Xác nhận mật khẩu',
                        en: 'Confirm password',
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Switch to full login ─────────────────────────────────
          Center(
            child: TextButton.icon(
              onPressed: loading ? null : onSwitchToFullLogin,
              icon: Icon(
                Icons.switch_account_outlined,
                size: 16,
                color: scheme.primary,
              ),
              label: Text(
                LanguageService.tr(
                  vi: 'Đăng nhập bằng tài khoản khác',
                  en: 'Sign in with a different account',
                ),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Form Card (Full Login / Register) ────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final TextEditingController confirmPassCtrl;
  final bool obscure;
  final bool loading;
  final bool biometricLoading;
  final String? errorMsg;
  final bool isRegisterMode;
  final bool biometricAvailable;
  final bool hasSavedSession;
  final VoidCallback onToggleObscure;
  final VoidCallback onSwitchMode;
  final VoidCallback onBiometricLogin;
  final VoidCallback onSubmit;
  final VoidCallback? onBackToQuickLogin;
  final ColorScheme scheme;

  const _FormCard({
    required this.formKey,
    required this.fullNameCtrl,
    required this.phoneCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    required this.confirmPassCtrl,
    required this.obscure,
    required this.loading,
    required this.biometricLoading,
    required this.errorMsg,
    required this.isRegisterMode,
    required this.biometricAvailable,
    required this.hasSavedSession,
    required this.onToggleObscure,
    required this.onSwitchMode,
    required this.onBiometricLogin,
    required this.onSubmit,
    required this.onBackToQuickLogin,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header with optional back button ─────────────────
            Row(
              children: [
                if (hasSavedSession && onBackToQuickLogin != null && !isRegisterMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: onBackToQuickLogin,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRegisterMode
                            ? LanguageService.tr(vi: 'Đăng ký', en: 'Sign up')
                            : LanguageService.tr(
                                vi: 'Đăng nhập',
                                en: 'Sign in',
                              ),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        LanguageService.tr(
                          vi: isRegisterMode
                              ? 'Tạo tài khoản mới để bắt đầu quản lý tài chính.'
                              : 'Chào mừng trở lại! Vui lòng nhập thông tin.',
                          en: isRegisterMode
                              ? 'Create a new account to start managing your finances.'
                              : 'Welcome back! Please enter your credentials.',
                        ),
                        style: TextStyle(fontSize: 13, color: scheme.outline),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (isRegisterMode) ...[
              _InputField(
                controller: fullNameCtrl,
                label: LanguageService.tr(vi: 'Họ và tên', en: 'Full name'),
                hint: LanguageService.tr(vi: 'Nguyễn Văn A', en: 'John Doe'),
                prefixIcon: Icons.person_outline,
                scheme: scheme,
                validator: (v) {
                  if (!isRegisterMode) return null;
                  if (v == null || v.trim().isEmpty) {
                    return LanguageService.tr(
                      vi: 'Vui lòng nhập họ tên',
                      en: 'Please enter your full name',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _InputField(
                controller: phoneCtrl,
                label:
                    LanguageService.tr(vi: 'Số điện thoại', en: 'Phone number'),
                hint:
                    LanguageService.tr(vi: '0901 234 567', en: '+84 901 234 567'),
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                scheme: scheme,
                validator: (v) {
                  if (!isRegisterMode) return null;
                  if (v == null || v.trim().isEmpty) {
                    return LanguageService.tr(
                      vi: 'Vui lòng nhập số điện thoại',
                      en: 'Please enter your phone number',
                    );
                  }
                  final digits = v.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 9 || digits.length > 15) {
                    return LanguageService.tr(
                      vi: 'Số điện thoại không hợp lệ',
                      en: 'Invalid phone number',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
            ],

            // Email field
            _InputField(
              controller: emailCtrl,
              label: 'Email',
              hint: 'admin@g13.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              scheme: scheme,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return LanguageService.tr(
                    vi: 'Vui lòng nhập email',
                    en: 'Please enter email',
                  );
                }
                if (!v.contains('@')) {
                  return LanguageService.tr(
                    vi: 'Email không hợp lệ',
                    en: 'Invalid email address',
                  );
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Password field
            _InputField(
              controller: passCtrl,
              label: LanguageService.tr(vi: 'Mật khẩu', en: 'Password'),
              hint: '••••••',
              prefixIcon: Icons.lock_outline,
              obscureText: obscure,
              scheme: scheme,
              suffixIcon: IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: scheme.outline,
                  size: 20,
                ),
                onPressed: onToggleObscure,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return LanguageService.tr(
                    vi: 'Vui lòng nhập mật khẩu',
                    en: 'Please enter password',
                  );
                }
                if (v.length < 6) {
                  return LanguageService.tr(
                    vi: 'Mật khẩu tối thiểu 6 ký tự',
                    en: 'Password must be at least 6 characters',
                  );
                }
                return null;
              },
            ),

            if (isRegisterMode) ...[
              const SizedBox(height: 14),
              _InputField(
                controller: confirmPassCtrl,
                label: LanguageService.tr(
                  vi: 'Xác nhận mật khẩu',
                  en: 'Confirm password',
                ),
                hint: '••••••',
                prefixIcon: Icons.lock_person_outlined,
                obscureText: obscure,
                scheme: scheme,
                validator: (v) {
                  if (!isRegisterMode) return null;
                  if (v == null || v.isEmpty) {
                    return LanguageService.tr(
                      vi: 'Vui lòng xác nhận mật khẩu',
                      en: 'Please confirm your password',
                    );
                  }
                  if (v != passCtrl.text) {
                    return LanguageService.tr(
                      vi: 'Mật khẩu xác nhận không khớp',
                      en: 'Passwords do not match',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
            ],

            if (!isRegisterMode) const SizedBox(height: 20),

            // Error message
            if (errorMsg != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: scheme.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMsg!,
                        style: TextStyle(
                          color: scheme.onErrorContainer,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Login / Register button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: loading ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isRegisterMode
                            ? LanguageService.tr(vi: 'Đăng ký', en: 'Sign up')
                            : LanguageService.tr(
                                vi: 'Đăng nhập',
                                en: 'Sign in',
                              ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: loading ? null : onSwitchMode,
              child: Text(
                isRegisterMode
                    ? LanguageService.tr(
                        vi: 'Đã có tài khoản? Đăng nhập',
                        en: 'Already have an account? Sign in',
                      )
                    : LanguageService.tr(
                        vi: 'Chưa có tài khoản? Đăng ký',
                        en: 'No account yet? Sign up',
                      ),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
            ),
            if (!isRegisterMode && biometricAvailable) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: (loading || biometricLoading) ? null : onBiometricLogin,
                icon: biometricLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.fingerprint),
                label: Text(
                  LanguageService.tr(
                    vi: 'Đăng nhập bằng sinh trắc học',
                    en: 'Sign in with biometrics',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Input Field ──────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ColorScheme scheme;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    required this.scheme,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon, size: 20, color: scheme.primary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }
}
