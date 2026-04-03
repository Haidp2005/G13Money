import '../models/transaction.dart';

class TransactionsRepository {
  TransactionsRepository._();

  static final TransactionsRepository instance = TransactionsRepository._();

  final List<MoneyTransaction> _transactions = [
    MoneyTransaction(
      id: 'txn-salary-apr',
      title: 'Lương tháng 4',
      category: 'Lương',
      walletName: 'Vietcombank',
      amount: 12000000,
      date: DateTime(2026, 4, 1),
      isIncome: true,
    ),
    MoneyTransaction(
      id: 'txn-food-01',
      title: 'Ăn uống',
      category: 'Ăn uống',
      walletName: 'Tiền mặt',
      amount: 120000,
      date: DateTime(2026, 4, 2),
      isIncome: false,
    ),
    MoneyTransaction(
      id: 'txn-transport-01',
      title: 'Di chuyển',
      category: 'Di chuyển',
      walletName: 'Vietcombank',
      amount: 60000,
      date: DateTime(2026, 4, 2),
      isIncome: false,
    ),
    MoneyTransaction(
      id: 'txn-shopping-01',
      title: 'Mua sắm cá nhân',
      category: 'Mua sắm',
      walletName: 'Momo',
      amount: 250000,
      date: DateTime(2026, 4, 3),
      isIncome: false,
    ),
  ];

  List<MoneyTransaction> get transactions => List.unmodifiable(_transactions);
}
