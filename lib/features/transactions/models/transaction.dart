class MoneyTransaction {
  final String id;
  final String title;
  final String category;
  final String walletName;
  final double amount;
  final DateTime date;
  final bool isIncome;

  const MoneyTransaction({
    required this.id,
    required this.title,
    required this.category,
    required this.walletName,
    required this.amount,
    required this.date,
    required this.isIncome,
  });
}
