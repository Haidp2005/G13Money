import 'package:flutter/material.dart';
import '../../../core/services/language_service.dart';

class MoneyBottomNav extends StatelessWidget {
	const MoneyBottomNav({
		super.key,
		required this.currentIndex,
		required this.onItemTap,
		required this.onAddTap,
	});

	final int currentIndex;
	final ValueChanged<int> onItemTap;
	final VoidCallback onAddTap;

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;

		return Container(
			height: 84,
			decoration: BoxDecoration(
				color: scheme.surface,
				border: Border(
					top: BorderSide(
						color: scheme.outlineVariant.withValues(alpha: 0.3),
					),
				),
				boxShadow: [
					BoxShadow(
						color: Colors.black.withValues(alpha: 0.06),
						blurRadius: 12,
						offset: const Offset(0, -4),
					),
				],
			),
			child: Row(
				mainAxisAlignment: MainAxisAlignment.spaceAround,
				children: [
					_NavItem(
						icon: Icons.pie_chart_rounded,
						activeIcon: Icons.pie_chart_rounded,
						label: LanguageService.tr(vi: 'Tổng quan', en: 'Overview'),
						active: currentIndex == 0,
						onTap: () => onItemTap(0),
					),
					_NavItem(
						icon: Icons.receipt_long_outlined,
						activeIcon: Icons.receipt_long_rounded,
						label: LanguageService.tr(vi: 'Giao dịch', en: 'Transactions'),
						active: currentIndex == 1,
						onTap: () => onItemTap(1),
					),
					GestureDetector(
						onTap: onAddTap,
						child: Container(
							width: 58,
							height: 58,
							decoration: BoxDecoration(
								gradient: LinearGradient(
									begin: Alignment.topLeft,
									end: Alignment.bottomRight,
									colors: [
										scheme.primary,
										scheme.tertiary,
									],
								),
								shape: BoxShape.circle,
								boxShadow: [
									BoxShadow(
										color: scheme.primary.withValues(alpha: 0.4),
										blurRadius: 16,
										offset: const Offset(0, 5),
									),
								],
							),
							child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
						),
					),
					_NavItem(
						icon: Icons.savings_outlined,
						activeIcon: Icons.savings_rounded,
						label: LanguageService.tr(vi: 'Ngân sách', en: 'Budgets'),
						active: currentIndex == 3,
						onTap: () => onItemTap(3),
					),
					_NavItem(
						icon: Icons.manage_accounts_outlined,
						activeIcon: Icons.manage_accounts_rounded,
						label: LanguageService.tr(vi: 'Tài khoản', en: 'Account'),
						active: currentIndex == 4,
						onTap: () => onItemTap(4),
					),
				],
			),
		);
	}
}

class _NavItem extends StatelessWidget {
	const _NavItem({
		required this.icon,
		required this.label,
		required this.active,
		required this.onTap,
		this.activeIcon,
	});

	final IconData icon;
	final IconData? activeIcon;
	final String label;
	final bool active;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		final scheme = Theme.of(context).colorScheme;
		final Color color = active ? scheme.primary : scheme.outline;
		final displayIcon = active ? (activeIcon ?? icon) : icon;

		return Expanded(
			child: InkWell(
				onTap: onTap,
				splashColor: scheme.primary.withValues(alpha: 0.08),
				highlightColor: Colors.transparent,
				child: Column(
					mainAxisAlignment: MainAxisAlignment.center,
					children: [
						AnimatedContainer(
							duration: const Duration(milliseconds: 220),
							curve: Curves.easeOutBack,
							padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
							decoration: BoxDecoration(
								color: active
										? scheme.primaryContainer.withValues(alpha: 0.7)
										: Colors.transparent,
								borderRadius: BorderRadius.circular(14),
							),
							child: AnimatedScale(
								scale: active ? 1.1 : 1.0,
								duration: const Duration(milliseconds: 220),
								curve: Curves.easeOutBack,
								child: Icon(displayIcon, color: color, size: 24),
							),
						),
						const SizedBox(height: 4),
						AnimatedDefaultTextStyle(
							duration: const Duration(milliseconds: 200),
							style: TextStyle(
								color: color,
								fontSize: 11,
								fontWeight: active ? FontWeight.w700 : FontWeight.w500,
							),
							child: Text(label),
						),
					],
				),
			),
		);
	}
}
