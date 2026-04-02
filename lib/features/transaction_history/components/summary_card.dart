import 'package:flutter/material.dart';

/// Thẻ tổng quan hiển thị tổng Tiền vào (Income) và Tiền ra (Expense)
class SummaryCard extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;

  const SummaryCard({
    Key? key,
    required this.totalIncome,
    required this.totalExpense,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E), // Màu xám tối tạo độ sâu so với nền đen
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Tiền vào', totalIncome, const Color(0xFF4A90E2)), // Màu xanh dương sáng
              _buildSummaryItem('Tiền ra', totalExpense, const Color(0xFFFF5252)), // Màu đỏ cam
            ],
          ),
          const Divider(color: Colors.grey, height: 32),
          InkWell(
            onTap: () {
              // TODO: Điều hướng xem báo cáo chi tiết
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Xem báo cáo',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
              ],
            ),
          )
        ],
      ),
    );
  }

  /// Nơi hiển thị giá trị Tiền vào / Tiền ra với màu sắc được truyền vào
  Widget _buildSummaryItem(String label, double amount, Color amountColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: amountColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        )
      ],
    );
  }
}
