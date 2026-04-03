import 'package:flutter/material.dart';

import '../../../core/models/app_notification.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/notification_service.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(LanguageService.tr(vi: 'Thông báo', en: 'Notifications')),
        actions: [
          IconButton(
            tooltip: LanguageService.tr(vi: 'Đánh dấu đã đọc', en: 'Mark all read'),
            onPressed: NotificationService.markAllAsRead,
            icon: const Icon(Icons.done_all),
          ),
          IconButton(
            tooltip: LanguageService.tr(vi: 'Xóa tất cả', en: 'Clear all'),
            onPressed: NotificationService.clearAll,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ValueListenableBuilder<NotificationPreferences>(
        valueListenable: NotificationService.preferences,
        builder: (context, prefs, _) {
          return ValueListenableBuilder<List<AppNotification>>(
            valueListenable: NotificationService.notifications,
            builder: (context, items, __) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Text(
                    LanguageService.tr(vi: 'Cài đặt thông báo', en: 'Notification settings'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          value: prefs.budgetAlerts,
                          onChanged: NotificationService.setBudgetAlerts,
                          title: Text(
                            LanguageService.tr(
                              vi: 'Cảnh báo ngân sách',
                              en: 'Budget alerts',
                            ),
                          ),
                        ),
                        SwitchListTile(
                          value: prefs.dailyReminder,
                          onChanged: NotificationService.setDailyReminder,
                          title: Text(
                            LanguageService.tr(
                              vi: 'Nhắc ghi giao dịch hằng ngày',
                              en: 'Daily transaction reminder',
                            ),
                          ),
                        ),
                        SwitchListTile(
                          value: prefs.billReminder,
                          onChanged: NotificationService.setBillReminder,
                          title: Text(
                            LanguageService.tr(
                              vi: 'Nhắc hóa đơn định kỳ',
                              en: 'Recurring bill reminders',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    LanguageService.tr(vi: 'Lịch sử thông báo', en: 'Notification history'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (items.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        LanguageService.tr(
                          vi: 'Chưa có thông báo nào',
                          en: 'No notifications yet',
                        ),
                        style: TextStyle(color: scheme.outline),
                      ),
                    )
                  else
                    ...items.map((item) {
                      return Card(
                        child: ListTile(
                          onTap: () => NotificationService.markAsRead(item.id),
                          leading: Icon(
                            _iconFor(item.type),
                            color: item.isRead ? scheme.outline : scheme.primary,
                          ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(item.message),
                          trailing: Text(
                            _timeLabel(item.createdAt),
                            style: TextStyle(fontSize: 12, color: scheme.outline),
                          ),
                        ),
                      );
                    }),
                ],
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.budgetExceeded:
        return Icons.warning_amber_rounded;
      case AppNotificationType.budgetWarning:
        return Icons.notifications_active_outlined;
      case AppNotificationType.reminder:
        return Icons.alarm_outlined;
      case AppNotificationType.system:
        return Icons.info_outline;
    }
  }

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
