import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/language_service.dart';
import '../state/notifications_state.dart';
import '../../transactions/ui/add_transaction_form_page.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  Future<void> _openReview(BuildContext context, WidgetRef ref, BankReviewTransaction item) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionFormPage(
          initialData: TransactionFormInitialData(
            transactionId: item.id,
            note: item.note.isEmpty ? item.title : item.note,
            walletName: item.walletName,
            category: item.categoryName,
            amount: item.amount,
            date: item.date,
            isIncome: item.isIncome,
          ),
        ),
      ),
    );

    if (updated == true) {
      await ref.read(bankNotificationsProvider.notifier).markReviewed(item);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final notificationsState = ref.watch(bankNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(LanguageService.tr(vi: 'Thông báo giao dịch', en: 'Transaction notifications')),
        actions: [
          IconButton(
            tooltip: LanguageService.tr(vi: 'Tải lại', en: 'Refresh'),
            onPressed: () => ref.read(bankNotificationsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: notificationsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 38),
                const SizedBox(height: 8),
                Text(
                  error.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () => ref.read(bankNotificationsProvider.notifier).refresh(),
                  child: Text(LanguageService.tr(vi: 'Thử lại', en: 'Retry')),
                ),
              ],
            ),
          ),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              LanguageService.tr(
                vi: 'Cần bổ sung danh mục',
                en: 'Need category update',
              ),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            if (data.needReviewItems.isEmpty)
              _emptyCard(
                context,
                LanguageService.tr(
                  vi: 'Không có giao dịch cần cập nhật',
                  en: 'No bank transactions need updates',
                ),
              )
            else
              ...data.needReviewItems.map((item) => _reviewTile(context, ref, item)),
            const SizedBox(height: 18),
            Text(
              LanguageService.tr(
                vi: 'Đã cập nhật gần đây',
                en: 'Recently updated',
              ),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            if (data.reviewedItems.isEmpty)
              _emptyCard(
                context,
                LanguageService.tr(
                  vi: 'Chưa có giao dịch đã cập nhật',
                  en: 'No reviewed bank transactions yet',
                ),
              )
            else
              ...data.reviewedItems.map((item) => _doneTile(context, item)),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(color: scheme.outline)),
    );
  }

  Widget _reviewTile(BuildContext context, WidgetRef ref, BankReviewTransaction item) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.notifications_active_outlined),
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${LanguageService.tr(vi: 'Số tiền', en: 'Amount')}: ${_money(item.amount)}\n'
          '${LanguageService.tr(vi: 'Danh mục', en: 'Category')}: '
          '${item.categoryName.trim().isEmpty ? LanguageService.tr(vi: 'Chưa có', en: 'Missing') : item.categoryName}',
        ),
        isThreeLine: true,
        trailing: FilledButton(
          onPressed: () => _openReview(context, ref, item),
          child: Text(LanguageService.tr(vi: 'Sua', en: 'Edit')),
        ),
      ),
    );
  }

  Widget _doneTile(BuildContext context, BankReviewTransaction item) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.check_circle_outline, color: Colors.green),
        title: Text(item.title),
        subtitle: Text(
          '${LanguageService.tr(vi: 'Số tiền', en: 'Amount')}: ${_money(item.amount)}\n'
          '${LanguageService.tr(vi: 'Danh mục', en: 'Category')}: ${item.categoryName}',
        ),
        isThreeLine: true,
      ),
    );
  }

  String _money(double amount) {
    final raw = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(raw[i]);
    }
    return '${buffer.toString()} đ';
  }
}

