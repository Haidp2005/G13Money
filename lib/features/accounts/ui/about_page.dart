import 'package:flutter/material.dart';
import '../../../core/services/language_service.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          // ── Hero Header ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: scheme.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              LanguageService.tr(vi: 'Giới thiệu', en: 'About'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroHeader(scheme: scheme),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // App tagline
                      _TaglineCard(scheme: scheme, isDark: isDark),
                      const SizedBox(height: 20),

                      // Features
                      _SectionTitle(
                        LanguageService.tr(vi: 'Tính năng nổi bật', en: 'Key Features'),
                        scheme,
                      ),
                      const SizedBox(height: 12),
                      _FeaturesCard(scheme: scheme),
                      const SizedBox(height: 20),

                      // Team
                      _SectionTitle(
                        LanguageService.tr(vi: 'Nhóm phát triển', en: 'Development Team'),
                        scheme,
                      ),
                      const SizedBox(height: 12),
                      _TeamCard(scheme: scheme),
                      const SizedBox(height: 20),

                      // App info
                      _SectionTitle(
                        LanguageService.tr(vi: 'Thông tin ứng dụng', en: 'App Info'),
                        scheme,
                      ),
                      const SizedBox(height: 12),
                      _AppInfoCard(scheme: scheme),
                      const SizedBox(height: 20),

                      // Footer
                      _FooterNote(scheme: scheme),
                    ],
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

// ── Hero Header ─────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final ColorScheme scheme;
  const _HeroHeader({required this.scheme});

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
            const SizedBox(height: 16),
            // App icon
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 48,
                  color: scheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'G13 Money',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                LanguageService.tr(
                  vi: 'Phiên bản 1.0.0',
                  en: 'Version 1.0.0',
                ),
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tagline ──────────────────────────────────────────────────────────────────

class _TaglineCard extends StatelessWidget {
  final ColorScheme scheme;
  final bool isDark;
  const _TaglineCard({required this.scheme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            scheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: scheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                LanguageService.tr(vi: 'Về ứng dụng', en: 'About the App'),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            LanguageService.tr(
              vi:
                  'G13 Money là ứng dụng quản lý tài chính cá nhân thông minh, '
                  'giúp bạn theo dõi thu chi, lập ngân sách và kiểm soát tài chính '
                  'một cách hiệu quả và đơn giản.',
              en:
                  'G13 Money is a smart personal finance management app that helps '
                  'you track income and expenses, set budgets, and take control of '
                  'your finances effectively and effortlessly.',
            ),
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: scheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Features Card ────────────────────────────────────────────────────────────

class _FeaturesCard extends StatelessWidget {
  final ColorScheme scheme;
  const _FeaturesCard({required this.scheme});

  @override
  Widget build(BuildContext context) {
    final features = [
      _Feature(
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFF4CAF50),
        title: LanguageService.tr(vi: 'Quản lý giao dịch', en: 'Transaction Management'),
        desc: LanguageService.tr(
          vi: 'Ghi chép thu chi nhanh chóng và trực quan',
          en: 'Record income and expenses quickly and intuitively',
        ),
      ),
      _Feature(
        icon: Icons.pie_chart_rounded,
        color: const Color(0xFF2196F3),
        title: LanguageService.tr(vi: 'Báo cáo thống kê', en: 'Financial Reports'),
        desc: LanguageService.tr(
          vi: 'Biểu đồ phân tích chi tiêu theo danh mục',
          en: 'Charts analyzing spending by category',
        ),
      ),
      _Feature(
        icon: Icons.savings_rounded,
        color: const Color(0xFFFF9800),
        title: LanguageService.tr(vi: 'Quản lý ngân sách', en: 'Budget Management'),
        desc: LanguageService.tr(
          vi: 'Đặt hạn mức chi tiêu và theo dõi tiến độ',
          en: 'Set spending limits and track progress',
        ),
      ),
      _Feature(
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF9C27B0),
        title: LanguageService.tr(vi: 'Đa ví/tài khoản', en: 'Multi-Wallet'),
        desc: LanguageService.tr(
          vi: 'Quản lý nhiều ví và tài khoản ngân hàng',
          en: 'Manage multiple wallets and bank accounts',
        ),
      ),
      _Feature(
        icon: Icons.category_rounded,
        color: const Color(0xFFE91E63),
        title: LanguageService.tr(vi: 'Danh mục tùy chỉnh', en: 'Custom Categories'),
        desc: LanguageService.tr(
          vi: 'Tạo và chỉnh sửa danh mục theo nhu cầu',
          en: 'Create and customize categories to your needs',
        ),
      ),
      _Feature(
        icon: Icons.notifications_active_rounded,
        color: const Color(0xFF00BCD4),
        title: LanguageService.tr(vi: 'Thông báo thông minh', en: 'Smart Notifications'),
        desc: LanguageService.tr(
          vi: 'Cảnh báo khi vượt ngân sách hoặc giao dịch bất thường',
          en: 'Alerts for budget overruns or unusual transactions',
        ),
      ),
    ];

    return _InfoCard(
      child: Column(
        children: features.map((f) {
          final isLast = f == features.last;
          return Column(
            children: [
              _FeatureItem(feature: f, scheme: scheme),
              if (!isLast) Divider(height: 1, indent: 56, color: scheme.outlineVariant),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _Feature {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  const _Feature({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
  });
}

class _FeatureItem extends StatelessWidget {
  final _Feature feature;
  final ColorScheme scheme;
  const _FeatureItem({required this.feature, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: feature.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(feature.icon, size: 22, color: feature.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature.desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.outline,
                    height: 1.4,
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

// ── Team Card ────────────────────────────────────────────────────────────────

class _TeamCard extends StatelessWidget {
  final ColorScheme scheme;
  const _TeamCard({required this.scheme});

  @override
  Widget build(BuildContext context) {
    final members = [
      _TeamMember(
        initials: 'G13',
        color: scheme.primary,
        name: LanguageService.tr(vi: 'Nhóm G13', en: 'Team G13'),
        role: LanguageService.tr(vi: 'Phát triển & Thiết kế', en: 'Development & Design'),
      ),
    ];

    return _InfoCard(
      child: Column(
        children: [
          ...members.map((m) => _TeamMemberTile(member: m, scheme: scheme)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.school_rounded, color: scheme.secondary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    LanguageService.tr(
                      vi:
                          'Ứng dụng được phát triển trong khuôn khổ dự án môn học, '
                          'với mục tiêu mang lại giải pháp quản lý tài chính cá nhân '
                          'hiện đại và dễ sử dụng.',
                      en:
                          'The app was developed as part of a course project, '
                          'aiming to deliver a modern and user-friendly personal '
                          'finance management solution.',
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
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

class _TeamMember {
  final String initials;
  final Color color;
  final String name;
  final String role;
  const _TeamMember({
    required this.initials,
    required this.color,
    required this.name,
    required this.role,
  });
}

class _TeamMemberTile extends StatelessWidget {
  final _TeamMember member;
  final ColorScheme scheme;
  const _TeamMemberTile({required this.member, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: member.color.withValues(alpha: 0.15),
            child: Text(
              member.initials,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: member.color,
                fontSize: member.initials.length > 2 ? 11 : 15,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.name,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                member.role,
                style: TextStyle(fontSize: 12, color: scheme.outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── App Info Card ────────────────────────────────────────────────────────────

class _AppInfoCard extends StatelessWidget {
  final ColorScheme scheme;
  const _AppInfoCard({required this.scheme});

  @override
  Widget build(BuildContext context) {
    final rows = [
      _InfoRowData(
        icon: Icons.tag_rounded,
        label: LanguageService.tr(vi: 'Phiên bản', en: 'Version'),
        value: '1.0.0',
      ),
      _InfoRowData(
        icon: Icons.build_rounded,
        label: LanguageService.tr(vi: 'Nền tảng', en: 'Platform'),
        value: 'Flutter',
      ),
      _InfoRowData(
        icon: Icons.phone_android_rounded,
        label: LanguageService.tr(vi: 'Hỗ trợ', en: 'Supported'),
        value: 'Android / iOS',
      ),
      _InfoRowData(
        icon: Icons.calendar_month_rounded,
        label: LanguageService.tr(vi: 'Năm phát hành', en: 'Release Year'),
        value: '2025',
      ),
    ];

    return _InfoCard(
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final idx = entry.key;
          final row = entry.value;
          return Column(
            children: [
              Padding(
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
                      child: Icon(row.icon, size: 18, color: scheme.primary),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      row.label,
                      style: TextStyle(fontSize: 14, color: scheme.outline),
                    ),
                    const Spacer(),
                    Text(
                      row.value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (idx < rows.length - 1)
                Divider(height: 1, indent: 50, color: scheme.outlineVariant),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _InfoRowData {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRowData({required this.icon, required this.label, required this.value});
}

// ── Footer ───────────────────────────────────────────────────────────────────

class _FooterNote extends StatelessWidget {
  final ColorScheme scheme;
  const _FooterNote({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.favorite_rounded, color: scheme.primary, size: 20),
          const SizedBox(height: 8),
          Text(
            LanguageService.tr(
              vi: 'Được xây dựng với tâm huyết bởi Nhóm G13',
              en: 'Built with passion by Team G13',
            ),
            style: TextStyle(
              fontSize: 13,
              color: scheme.outline,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '© 2025 G13 Money. All rights reserved.',
            style: TextStyle(fontSize: 11, color: scheme.outlineVariant),
          ),
        ],
      ),
    );
  }
}

// ── Shared ───────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: scheme.surface,
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

class _SectionTitle extends StatelessWidget {
  final String text;
  final ColorScheme scheme;
  const _SectionTitle(this.text, this.scheme);

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
