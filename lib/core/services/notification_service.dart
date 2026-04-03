import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';

class NotificationPreferences {
  final bool budgetAlerts;
  final bool dailyReminder;
  final bool billReminder;

  const NotificationPreferences({
    required this.budgetAlerts,
    required this.dailyReminder,
    required this.billReminder,
  });

  NotificationPreferences copyWith({
    bool? budgetAlerts,
    bool? dailyReminder,
    bool? billReminder,
  }) {
    return NotificationPreferences(
      budgetAlerts: budgetAlerts ?? this.budgetAlerts,
      dailyReminder: dailyReminder ?? this.dailyReminder,
      billReminder: billReminder ?? this.billReminder,
    );
  }
}

class NotificationService {
  static final ValueNotifier<NotificationPreferences> preferences =
      ValueNotifier(
    const NotificationPreferences(
      budgetAlerts: true,
      dailyReminder: false,
      billReminder: false,
    ),
  );

  static final ValueNotifier<List<AppNotification>> notifications =
      ValueNotifier(const []);

  static final Set<String> _uniqueKeys = <String>{};

  static int get unreadCount =>
      notifications.value.where((item) => !item.isRead).length;

  static void add(AppNotification notification) {
    notifications.value = [notification, ...notifications.value];
  }

  static void addUnique({
    required String uniqueKey,
    required AppNotification notification,
  }) {
    if (_uniqueKeys.contains(uniqueKey)) return;
    _uniqueKeys.add(uniqueKey);
    add(notification);
  }

  static void markAsRead(String id) {
    notifications.value = notifications.value
        .map((item) => item.id == id ? item.copyWith(isRead: true) : item)
        .toList(growable: false);
  }

  static void markAllAsRead() {
    notifications.value = notifications.value
        .map((item) => item.copyWith(isRead: true))
        .toList(growable: false);
  }

  static void clearAll() {
    notifications.value = const [];
    _uniqueKeys.clear();
  }

  static void setBudgetAlerts(bool value) {
    preferences.value = preferences.value.copyWith(budgetAlerts: value);
  }

  static void setDailyReminder(bool value) {
    preferences.value = preferences.value.copyWith(dailyReminder: value);
  }

  static void setBillReminder(bool value) {
    preferences.value = preferences.value.copyWith(billReminder: value);
  }
}
