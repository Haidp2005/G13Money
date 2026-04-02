import 'package:flutter/material.dart';

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
		return Container(
			height: 84,
			decoration: const BoxDecoration(
				color: Color(0xFF141518),
				border: Border(top: BorderSide(color: Color(0xFF21242A))),
			),
			child: Row(
				mainAxisAlignment: MainAxisAlignment.spaceAround,
				children: [
					_NavItem(
						icon: Icons.home_rounded,
						label: 'Tổng quan',
						active: currentIndex == 0,
						onTap: () => onItemTap(0),
					),
					_NavItem(
						icon: Icons.account_balance_wallet_outlined,
						label: 'Sổ giao dịch',
						active: currentIndex == 1,
						onTap: () => onItemTap(1),
					),
					GestureDetector(
						onTap: onAddTap,
						child: Container(
							width: 58,
							height: 58,
							decoration: BoxDecoration(
								color: const Color(0xFF2DCC5A),
								shape: BoxShape.circle,
								border: Border.all(color: const Color(0xFF1C9D43), width: 2),
							),
							child: const Icon(Icons.add, color: Colors.white, size: 34),
						),
					),
					_NavItem(
						icon: Icons.content_paste_go_outlined,
						label: 'Ngân sách',
						active: currentIndex == 3,
						onTap: () => onItemTap(3),
					),
					_NavItem(
						icon: Icons.person_outline_rounded,
						label: 'Tài khoản',
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
	});

	final IconData icon;
	final String label;
	final bool active;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		final Color color = active ? Colors.white : const Color(0xFF858B96);

		return Expanded(
			child: InkWell(
				onTap: onTap,
				child: Column(
					mainAxisAlignment: MainAxisAlignment.center,
					children: [
						Icon(icon, color: color, size: 26),
						const SizedBox(height: 4),
						Text(
							label,
							style: TextStyle(
								color: color,
								fontSize: 11,
								fontWeight: active ? FontWeight.w700 : FontWeight.w500,
							),
						),
					],
				),
			),
		);
	}
}
