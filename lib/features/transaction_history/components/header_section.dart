import 'package:flutter/material.dart';

/// Section Header bao gồm thông tin số dư, các nút chức năng và Tab thời gian.
/// Sử dụng [StatelessWidget] để tối ưu hiệu suất do section này chỉ hiển thị dữ liệu tĩnh ở mức UI.
class HeaderSection extends StatelessWidget {
  final double totalBalance;
  final String currentMonth;

  const HeaderSection({
    Key? key,
    required this.totalBalance,
    required this.currentMonth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      color: Colors.black, // Nền đen sâu theo chuẩn Dark Mode
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopRow(context),
          const SizedBox(height: 16),
          _buildBalance(),
          const SizedBox(height: 20),
          _buildTimeTabs(),
        ],
      ),
    );
  }

  /// Hàng trên cùng bao gồm Search và More options
  Widget _buildTopRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Giao dịch',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                // TODO: Xử lý sự kiện tìm kiếm
              },
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {
                // TODO: Xử lý sự kiện menu mở rộng
              },
            ),
          ],
        )
      ],
    );
  }

  /// Hiển thị Số dư tổng
  Widget _buildBalance() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Số dư tổng',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${totalBalance.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Các tab thời gian: Tháng trước, Tháng này, vv.
  Widget _buildTimeTabs() {
    return Row(
      children: [
        _buildTabItem('Tháng trước', false),
        const SizedBox(width: 16),
        _buildTabItem(currentMonth, true),
        const SizedBox(width: 16),
        _buildTabItem('Tháng sau', false),
      ],
    );
  }

  /// Helper xây dựng Tab. Tuỳ chỉnh màu sắc cho tab đang được chọn.
  Widget _buildTabItem(String title, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.grey[800] : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
