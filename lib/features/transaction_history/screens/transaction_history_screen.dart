import 'package:flutter/material.dart';

import '../models/transaction_model.dart';
import '../components/header_section.dart';
import '../components/summary_card.dart';
import '../components/transaction_group.dart';
import '../components/bottom_nav_bar.dart';

/// Màn hình chính Lịch sử giao dịch (Transaction History)
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  int _currentNavIndex = 0;

  // Dữ liệu mẫu (Mock Data)
  final List<TransactionModel> _mockTransactions1 = [
    TransactionModel(
      id: '1',
      categoryName: 'Ăn uống',
      note: 'Phở bò',
      amount: 15.50,
      date: DateTime.now(),
      iconData: '🍜',
      type: TransactionType.expense,
    ),
    TransactionModel(
      id: '2',
      categoryName: 'Lương',
      note: 'Công ty',
      amount: 2500.00,
      date: DateTime.now(),
      iconData: '💰',
      type: TransactionType.income,
    ),
  ];

  final List<TransactionModel> _mockTransactions2 = [
    TransactionModel(
      id: '3',
      categoryName: 'Mua sắm',
      note: 'Quần áo',
      amount: 120.00,
      date: DateTime.now().subtract(const Duration(days: 1)),
      iconData: '🛍️',
      type: TransactionType.expense,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Áp dụng Theme tối thống nhất tại đây để không cần lặp lại cho các con
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black, // Nền đen sâu
      ),
      child: Scaffold(
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header Section (Giao dịch, Số dư, Tab)
              const SliverToBoxAdapter(
                child: HeaderSection(
                  totalBalance: 12050.75,
                  currentMonth: 'Tháng này',
                ),
              ),

              // Summary Card (Thu - Chi)
              const SliverToBoxAdapter(
                child: SummaryCard(
                  totalIncome: 3500.00,
                  totalExpense: 1245.50,
                ),
              ),

              // Danh sách nhóm lịch sử giao dịch
              SliverList(
                delegate: SliverChildListDelegate([
                  TransactionGroup(
                    dateHeader: 'Hôm nay',
                    transactions: _mockTransactions1,
                  ),
                  TransactionGroup(
                    dateHeader: 'Hôm qua',
                    transactions: _mockTransactions2,
                  ),
                  const SizedBox(height: 80), // Chừa không gian cho Bottom Nav Bar & FAB
                ]),
              ),
            ],
          ),
        ),

        // Nút FAB nổi bật ở giữa BottomNavBar
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF4A90E2), // Xanh dương thương hiệu
          onPressed: () {
            // TODO: Mở màn hình thêm giao dịch
          },
          child: const Icon(Icons.add, size: 32, color: Colors.white),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        // Bottom Nav Bar
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentNavIndex,
          onTap: (index) {
            setState(() {
              _currentNavIndex = index;
            });
          },
        ),
      ),
    );
  }
}
