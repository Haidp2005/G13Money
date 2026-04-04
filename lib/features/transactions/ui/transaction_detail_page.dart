import 'package:flutter/material.dart';

import '../data/transactions_repository.dart';
import '../models/transaction.dart';
import 'add_transaction_form_page.dart';

class TransactionDetailPage extends StatefulWidget {
  final MoneyTransaction transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  bool _isProcessing = false;

  String _formatAmount(double amount, bool isIncome) {
    final raw = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(raw[i]);
    }
    return '${isIncome ? '+' : '-'}${buffer.toString()} đ';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _editTransaction() async {
    final tx = widget.transaction;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionFormPage(
          initialData: TransactionFormInitialData(
            transactionId: tx.id,
            note: tx.title,
            walletName: tx.walletName,
            category: tx.category,
            amount: tx.amount,
            date: tx.date,
            isIncome: tx.isIncome,
            attachmentUrls: tx.attachmentUrls,
          ),
        ),
      ),
    );

    if (!mounted) return;
    if (updated == true) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteTransaction() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoá giao dịch'),
        content: const Text('Bạn có chắc chắn muốn xoá giao dịch này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await TransactionsRepository.instance.deleteTransaction(widget.transaction.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xoá giao dịch')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết giao dịch'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _formatAmount(tx.amount, tx.isIncome),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: tx.isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _InfoRow(label: 'Danh mục', value: tx.category),
                    _InfoRow(label: 'Ví', value: tx.walletName),
                    _InfoRow(label: 'Ngày', value: _formatDate(tx.date)),
                    _InfoRow(label: 'Loại', value: tx.isIncome ? 'Thu nhập' : 'Chi tiêu'),
                    if (tx.attachmentUrls.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Ảnh chi tiết',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 88,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: tx.attachmentUrls.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) => ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              tx.attachmentUrls[index],
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _isProcessing ? null : _editTransaction,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Sửa giao dịch'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _isProcessing ? null : _deleteTransaction,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Xoá giao dịch'),
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.error,
                side: BorderSide(color: scheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
