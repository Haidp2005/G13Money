import 'package:cloud_firestore/cloud_firestore.dart';

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

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'categoryName': category,
      'walletName': walletName,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'isIncome': isIncome,
      'type': isIncome ? 'income' : 'expense',
      'year': date.year,
      'month': date.month,
      'day': date.day,
      'yearMonth': '${date.year}-${date.month.toString().padLeft(2, '0')}',
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory MoneyTransaction.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final rawDate = data['date'];
    DateTime dateValue;
    if (rawDate is Timestamp) {
      dateValue = rawDate.toDate();
    } else if (rawDate is DateTime) {
      dateValue = rawDate;
    } else {
      dateValue = DateTime.now();
    }

    return MoneyTransaction(
      id: id,
      title: (data['title'] as String?) ?? '',
      category: (data['categoryName'] as String?) ?? '',
      walletName: (data['walletName'] as String?) ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      date: dateValue,
      isIncome: (data['isIncome'] as bool?) ?? false,
    );
  }
}
