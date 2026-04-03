import 'package:flutter/material.dart';
import '../../shared/widgets/bottom_nav.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  // Dữ liệu giả lập
  final List<_TransactionGroupData> _groups = [
    _TransactionGroupData(
      dateStr: '02',
      dayOfWeek: 'Thứ Ba',
      monthStr: 'Tháng 4 2026',
      transactions: [
        _TransactionItemData(
          title: 'Ăn uống',
          note: 'Ăn trưa',
          amountStr: '50,000',
          isIncome: false,
          icon: Icons.restaurant,
          iconColor: Colors.orange,
        ),
        _TransactionItemData(
          title: 'Lương',
          note: 'Lương tháng 3',
          amountStr: '15,000,000',
          isIncome: true,
          icon: Icons.attach_money,
          iconColor: Colors.green,
        ),
      ],
    ),
    _TransactionGroupData(
      dateStr: '01',
      dayOfWeek: 'Thứ Hai',
      monthStr: 'Tháng 4 2026',
      transactions: [
        _TransactionItemData(
          title: 'Mua sắm',
          note: 'Shopee',
          amountStr: '250,000',
          isIncome: false,
          icon: Icons.shopping_bag,
          iconColor: Colors.blue,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Nền xám đậm / đen
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSummaryCard(),
            Expanded(
              child: _buildTransactionList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: MoneyBottomNav(
        currentIndex: 1, // 1 là Sổ giao dịch đang active
        onItemTap: (index) {
          // Xử lý chuyển tab tại đây
        },
        onAddTap: () {
          // Xử lý khi nhấn nút Thêm (+)
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFF1A1A1A), // Background header
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Icon(Icons.search, color: Colors.white, size: 28),
              Text(
                'Lịch sử giao dịch',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'sans-serif',
                ),
              ),
              Icon(Icons.more_horiz, color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Số dư',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            '12,500,000 đ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontFamily: 'sans-serif',
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTab('Tháng trước', false),
              const SizedBox(width: 48),
              _buildTab('Tháng này', true),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isActive) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey,
            fontSize: 16,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            fontFamily: 'sans-serif',
          ),
        ),
        const SizedBox(height: 8),
        if (isActive)
          Container(
            height: 2,
            width: 60,
            color: Colors.white,
          )
        else
          Container(
            height: 2,
            width: 60,
            color: Colors.transparent,
          ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Nền thẻ
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Tiền vào', '15,000,000', const Color(0xFF4DABF7)),
          const SizedBox(height: 12),
          _buildSummaryRow('Tiền ra', '2,500,000', const Color(0xFFFF6B6B)),
          const SizedBox(height: 16),
          Divider(color: Colors.grey[800], height: 1),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight, // Nằm sát lề phải
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D5A27), // Xanh lá mờ
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Xem báo cáo',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    fontFamily: 'sans-serif',
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey, 
            fontSize: 16,
            fontFamily: 'sans-serif',
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'sans-serif',
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: _groups.length,
      itemBuilder: (context, index) {
        final group = _groups[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề ngày tháng
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      group.dateStr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'sans-serif',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.dayOfWeek,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            fontFamily: 'sans-serif',
                          ),
                        ),
                        Text(
                          group.monthStr,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            fontFamily: 'sans-serif',
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              // Khối các giao dịch trong cùng 1 ngày
              Container(
                color: const Color(0xFF1E1E1E), // Nền cho khối giao dịch
                child: Column(
                  children: group.transactions.map((t) {
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: t.iconColor.withOpacity(0.15),
                        radius: 20,
                        child: Icon(t.icon, color: t.iconColor, size: 22),
                      ),
                      title: Text(
                        t.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'sans-serif',
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          t.note,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                            fontFamily: 'sans-serif',
                          ),
                        ),
                      ),
                      trailing: Text(
                        '${t.isIncome ? '+' : '-'}${t.amountStr}',
                        style: TextStyle(
                          color: t.isIncome ? const Color(0xFF4DABF7) : const Color(0xFFFF6B6B),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'sans-serif',
                        ),
                      ),
                    );
                  }).toList(),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

class _TransactionGroupData {
  final String dateStr;
  final String dayOfWeek;
  final String monthStr;
  final List<_TransactionItemData> transactions;

  _TransactionGroupData({
    required this.dateStr,
    required this.dayOfWeek,
    required this.monthStr,
    required this.transactions,
  });
}

class _TransactionItemData {
  final String title;
  final String note;
  final String amountStr;
  final bool isIncome;
  final IconData icon;
  final Color iconColor;

  _TransactionItemData({
    required this.title,
    required this.note,
    required this.amountStr,
    required this.isIncome,
    required this.icon,
    required this.iconColor,
  });
}
