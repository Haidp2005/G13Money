import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../auth/ui/login_page.dart';
import '../../../core/models/user_model.dart';
import '../../../app/routes.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
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
                tooltip: 'Chỉnh sửa',
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.editProfile),
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
              child: Center(
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
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Tài khoản của tôi',
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
                'Thông tin cá nhân',
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
            label: 'Họ và tên',
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
            label: 'Số điện thoại',
            value: user.phone,
            scheme: scheme,
          ),
          const Divider(height: 1, indent: 48),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Ngày tham gia',
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
    final settings = [
      (Icons.notifications_outlined, 'Thông báo', 'Quản lý thông báo'),
      (
        Icons.account_balance_wallet_outlined,
        'Ngân sách',
        'Hạn mức chi tiêu theo danh mục',
      ),
      (Icons.lock_outline, 'Bảo mật', 'Đổi mật khẩu & bảo mật'),
      (Icons.language_outlined, 'Ngôn ngữ', 'Tiếng Việt'),
      (Icons.color_lens_outlined, 'Giao diện', 'Chủ đề sáng'),
      (Icons.help_outline, 'Trợ giúp', 'FAQ & hỗ trợ'),
    ];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Thông tin cá nhân (nút bấm) ──────────────────────────
          _CardTitle('Tài khoản', scheme),
          const SizedBox(height: 4),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 0,
              vertical: 2,
            ),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.person_outline,
                size: 20,
                color: scheme.primary,
              ),
            ),
            title: const Text(
              'Thông tin cá nhân',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              'Xem thông tin tài khoản của bạn',
              style: TextStyle(fontSize: 12, color: scheme.outline),
            ),
            trailing: Icon(Icons.chevron_right, color: scheme.outline),
            onTap: () => _showInfoBottomSheet(context, user, scheme),
          ),
          const Divider(height: 8),
          // ── Cài đặt ──────────────────────────────────────────────
          _CardTitle('Cài đặt', scheme),
          const SizedBox(height: 4),
          ...settings.map(
            (item) => _MenuItem(
              icon: item.$1,
              title: item.$2,
              subtitle: item.$3,
              scheme: scheme,
              onTap: () {
                if (item.$2 == 'Ngân sách') {
                  Navigator.pushNamed(context, AppRoutes.budgets);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
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
        label: const Text('Đăng xuất'),
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
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () {
              AuthService.logout();
              Navigator.pop(ctx);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (_) => false,
              );
            },
            child: Text(
              'Đăng xuất',
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
