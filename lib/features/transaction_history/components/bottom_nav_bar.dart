import 'package:flutter/material.dart';

/// Thanh điều hướng dưới cùng, gồm 5 tabs với nút "Thêm" ở giữa nổi bật
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sử dụng BottomAppBar để dễ dàng nhúng nút FloatingActionButton ở giữa
    return BottomAppBar(
      color: const Color(0xFF1C1C1E),
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_outlined, 0),
            _buildNavItem(Icons.account_balance_wallet_outlined, 1),
            const SizedBox(width: 48), // Khoảng trống cho FAB
            _buildNavItem(Icons.pie_chart_outline, 3),
            _buildNavItem(Icons.person_outline, 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = currentIndex == index;
    return IconButton(
      icon: Icon(icon, color: isSelected ? Colors.white : Colors.grey),
      onPressed: () => onTap(index),
    );
  }
}
