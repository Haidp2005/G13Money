import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/state/app_settings_providers.dart';
import '../state/profile_state.dart';
import '../../auth/ui/login_page.dart';
import '../../../core/models/user_model.dart';
import '../../../app/routes.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(profileRefreshTickProvider);
    final user = AuthService.currentUser;
    if (user == null) {
      return const LoginPage();
    }
    return _ProfileView(user: user);
  }
}

class _ProfileView extends StatelessWidget {
  final UserModel user;
  const _ProfileView({required this.user});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          // ── Header SliverAppBar ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: scheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: _HeaderBackground(user: user, scheme: scheme),
            ),
            actions: [
              IconButton(
                tooltip: LanguageService.tr(vi: 'Chỉnh sửa', en: 'Edit'),
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.editProfile),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // ── Body ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                children: [
                  _MenuCard(user: user, scheme: scheme),
                  const SizedBox(height: 24),
                  _LogoutButton(scheme: scheme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _HeaderBackground extends StatelessWidget {
  final UserModel user;
  final ColorScheme scheme;
  const _HeaderBackground({required this.user, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.tertiary],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            // Avatar (Điểm nhấn duy nhất)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.25),
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: ClipOval(
                child: user.avatarUrl.trim().isEmpty
                    ? Center(
                        child: Text(
                          user.avatarInitials,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : Image.network(
                        user.avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            user.avatarInitials,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                LanguageService.tr(vi: 'Tài khoản của tôi', en: 'My account'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info Bottom Sheet ────────────────────────────────────────────────────────

void _showInfoBottomSheet(
  BuildContext context,
  UserModel user,
  ColorScheme scheme,
) {
  final joinedStr =
      '${user.joinedDate.day.toString().padLeft(2, '0')}/'
      '${user.joinedDate.month.toString().padLeft(2, '0')}/'
      '${user.joinedDate.year}';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: scheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_outline,
                  color: scheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                LanguageService.tr(vi: 'Thông tin cá nhân', en: 'Personal information'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.badge_outlined,
            label: LanguageService.tr(vi: 'Họ và tên', en: 'Full name'),
            value: user.fullName,
            scheme: scheme,
          ),
          const Divider(height: 1, indent: 48),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user.email,
            scheme: scheme,
          ),
          const Divider(height: 1, indent: 48),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: LanguageService.tr(vi: 'Số điện thoại', en: 'Phone number'),
            value: user.phone,
            scheme: scheme,
          ),
          const Divider(height: 1, indent: 48),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: LanguageService.tr(vi: 'Ngày tham gia', en: 'Joined date'),
            value: joinedStr,
            scheme: scheme,
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme scheme;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: scheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: scheme.outline),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Menu Card ────────────────────────────────────────────────────────────────

class _MenuCard extends StatelessWidget {
  final UserModel user;
  final ColorScheme scheme;
  const _MenuCard({required this.user, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final settings = <_SettingEntry>[
      _SettingEntry(
        icon: Icons.notifications_outlined,
        title: LanguageService.tr(vi: 'Thông báo', en: 'Notifications'),
        subtitle: LanguageService.tr(vi: 'Cài đặt cảnh báo giao dịch & ngân sách', en: 'Configure transaction & budget alerts'),
      ),
      _SettingEntry(
        icon: Icons.savings_outlined,
        title: LanguageService.tr(vi: 'Ngân sách', en: 'Budgets'),
        subtitle: LanguageService.tr(
          vi: 'Hạn mức chi tiêu theo danh mục',
          en: 'Spending limits by category',
        ),
      ),
      _SettingEntry(
        icon: Icons.account_balance_wallet_outlined,
        title: LanguageService.tr(vi: 'Ví/Tài khoản', en: 'Wallets/Accounts'),
        subtitle: LanguageService.tr(
          vi: 'Quản lý ví tiền, ngân hàng, ví điện tử',
          en: 'Manage cash, bank and e-wallet accounts',
        ),
      ),
      _SettingEntry(
        icon: Icons.category_outlined,
        title: LanguageService.tr(vi: 'Danh mục', en: 'Categories'),
        subtitle: LanguageService.tr(
          vi: 'Tạo và chỉnh sửa danh mục giao dịch',
          en: 'Create and edit transaction categories',
        ),
      ),
      _SettingEntry(
        icon: Icons.lock_outline,
        title: LanguageService.tr(vi: 'Bảo mật', en: 'Security'),
        subtitle: LanguageService.tr(vi: 'Đổi mật khẩu & bảo mật', en: 'Password & security'),
      ),
      _SettingEntry(
        icon: Icons.language_outlined,
        title: LanguageService.tr(vi: 'Ngôn ngữ', en: 'Language'),
        subtitle: LanguageService.currentLanguageLabel,
      ),
      _SettingEntry(
        icon: Icons.color_lens_outlined,
        title: LanguageService.tr(vi: 'Giao diện', en: 'Appearance'),
        subtitle: ThemeService.isDarkMode
            ? LanguageService.tr(vi: 'Chủ đề tối', en: 'Dark theme')
            : LanguageService.tr(vi: 'Chủ đề sáng', en: 'Light theme'),
      ),
      _SettingEntry(
        icon: Icons.info_outline,
        title: LanguageService.tr(vi: 'Giới thiệu ứng dụng', en: 'About App'),
        subtitle: LanguageService.tr(vi: 'Thông tin & tính năng của G13 Money', en: 'Info & features of G13 Money'),
      ),
    ];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(LanguageService.tr(vi: 'Tài khoản', en: 'Account'), scheme),
          const SizedBox(height: 4),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.person_outline, size: 20, color: scheme.primary),
            ),
            title: Text(
              LanguageService.tr(vi: 'Thông tin cá nhân', en: 'Personal information'),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              LanguageService.tr(
                vi: 'Xem thông tin tài khoản của bạn',
                en: 'View your account information',
              ),
              style: TextStyle(fontSize: 12, color: scheme.outline),
            ),
            trailing: Icon(Icons.chevron_right, color: scheme.outline),
            onTap: () => _showInfoBottomSheet(context, user, scheme),
          ),
          const Divider(height: 8),
          _CardTitle(LanguageService.tr(vi: 'Cài đặt', en: 'Settings'), scheme),
          const SizedBox(height: 4),
          ...settings.map(
            (item) => _MenuItem(
              icon: item.icon,
              title: item.title,
              subtitle: item.subtitle,
              scheme: scheme,
              onTap: () {
                if (item.icon == Icons.savings_outlined) {
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.home,
                    arguments: 3,
                  );
                } else if (item.icon == Icons.account_balance_wallet_outlined) {
                  Navigator.pushNamed(context, AppRoutes.manageWallets);
                } else if (item.icon == Icons.category_outlined) {
                  Navigator.pushNamed(context, AppRoutes.manageCategories);
                } else if (item.icon == Icons.notifications_outlined) {
                  Navigator.pushNamed(context, AppRoutes.notificationSettings);
                } else if (item.icon == Icons.lock_outline) {
                  Navigator.pushNamed(context, AppRoutes.changePassword);
                } else if (item.icon == Icons.language_outlined) {
                  _showLanguageBottomSheet(context);
                } else if (item.icon == Icons.color_lens_outlined) {
                  _showThemeBottomSheet(context);
                } else if (item.icon == Icons.info_outline) {
                  Navigator.pushNamed(context, AppRoutes.about);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

void _showThemeBottomSheet(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Consumer(
      builder: (context, ref, _) {
        final selectedMode = ref.watch(themeModeProvider);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LanguageService.tr(vi: 'Chọn giao diện', en: 'Choose appearance'),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                _OptionTile(
                  title: LanguageService.tr(vi: 'Sáng', en: 'Light'),
                  selected: selectedMode == ThemeMode.light,
                  onTap: () {
                    ThemeService.setThemeMode(ThemeMode.light);
                    Navigator.pop(context);
                  },
                ),
                _OptionTile(
                  title: LanguageService.tr(vi: 'Tối', en: 'Dark'),
                  selected: selectedMode == ThemeMode.dark,
                  onTap: () {
                    ThemeService.setThemeMode(ThemeMode.dark);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _SettingEntry {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

void _showLanguageBottomSheet(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Consumer(
      builder: (context, ref, _) {
        final selectedLanguage = ref.watch(appLanguageProvider);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LanguageService.tr(vi: 'Chọn ngôn ngữ', en: 'Choose language'),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                _OptionTile(
                  title: 'Tiếng Việt',
                  selected: selectedLanguage == AppLanguage.vietnamese,
                  onTap: () {
                    LanguageService.setLanguage(AppLanguage.vietnamese);
                    Navigator.pop(context);
                  },
                ),
                _OptionTile(
                  title: 'English',
                  selected: selectedLanguage == AppLanguage.english,
                  onTap: () {
                    LanguageService.setLanguage(AppLanguage.english);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ColorScheme scheme;
  final VoidCallback onTap;
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.scheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: scheme.secondary),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: scheme.outline),
      ),
      trailing: Icon(Icons.chevron_right, color: scheme.outline),
      onTap: onTap,
    );
  }
}

// ── Logout Button ────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final ColorScheme scheme;
  const _LogoutButton({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context),
        icon: const Icon(Icons.logout_rounded),
        label: Text(LanguageService.tr(vi: 'Đăng xuất', en: 'Log out')),
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.error,
          side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LanguageService.tr(vi: 'Đăng xuất', en: 'Log out')),
        content: Text(
          LanguageService.tr(
            vi: 'Bạn có chắc chắn muốn đăng xuất không?',
            en: 'Are you sure you want to log out?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LanguageService.tr(vi: 'Huỷ', en: 'Cancel')),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await AuthService.logout();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              navigator.pushNamedAndRemoveUntil(
                AppRoutes.login,
                (_) => false,
              );
            },
            child: Text(
              LanguageService.tr(vi: 'Đăng xuất', en: 'Log out'),
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared Widgets ───────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text(title),
      trailing: selected
          ? Icon(Icons.check_circle, color: scheme.primary)
          : Icon(Icons.circle_outlined, color: scheme.outline),
      onTap: onTap,
    );
  }
}

class _CardTitle extends StatelessWidget {
  final String text;
  final ColorScheme scheme;
  const _CardTitle(this.text, this.scheme);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: scheme.primary,
        letterSpacing: 0.5,
      ),
    );
  }
}
