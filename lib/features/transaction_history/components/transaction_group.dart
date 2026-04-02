import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import 'transaction_item.dart';

/// Nhóm các giao dịch theo ngày, ví dụ: "31 Thứ Ba"
class TransactionGroup extends StatelessWidget {
  final String dateHeader; // VD: "31 Thứ Ba"
  final List<TransactionModel> transactions;

  const TransactionGroup({
    Key? key,
    required this.dateHeader,
    required this.transactions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề ngày tháng của nhóm
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            dateHeader,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Danh sách các giao dịch trong ngày
        ...transactions.map((tx) => TransactionItem(transaction: tx)).toList(),
        const Divider(color: Color(0xFF1C1C1E), thickness: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}
