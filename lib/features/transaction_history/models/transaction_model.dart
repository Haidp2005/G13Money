class TransactionModel {
  final String id;
  final String categoryName;
  final String note;
  final double amount;
  final DateTime date;
  final String iconData; // Tên icon hoặc emoji
  final TransactionType type;

  const TransactionModel({
    required this.id,
    required this.categoryName,
    required this.note,
    required this.amount,
    required this.date,
    required this.iconData,
    required this.type,
  });
}

enum TransactionType { income, expense }
