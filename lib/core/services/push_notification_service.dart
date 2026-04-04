import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import 'auth_service.dart';

const AndroidNotificationChannel _defaultChannel = AndroidNotificationChannel(
  'g13money_default_channel',
  'G13 Money Notifications',
  description: 'General notifications for G13 Money',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _notificationsSubscription;
  static final Set<String> _seededNotificationDocIds = <String>{};
  static bool _hasSeededInitialNotifications = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initializeLocalNotifications();
    await _requestPermission();

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    FirebaseAuth.instance.authStateChanges().listen((user) async {
      await _notificationsSubscription?.cancel();
      _notificationsSubscription = null;
      _seededNotificationDocIds.clear();
      _hasSeededInitialNotifications = false;

      if (user != null) {
        await syncTokenForCurrentUser();
        _bindFirestoreNotifications(user.uid);
      }
    });

    _messaging.onTokenRefresh.listen((token) async {
      await _saveToken(token);
    });

    await syncTokenForCurrentUser();

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _onMessageOpenedApp(initialMessage);
    }

    _initialized = true;
  }

  static Future<void> syncTokenForCurrentUser() async {
    final token = await _messaging.getToken();
    await _saveToken(token);
  }

  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(settings);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_defaultChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  static Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );
  }

  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final android = notification.android;
    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _defaultChannel.id,
          _defaultChannel.name,
          channelDescription: _defaultChannel.description,
          icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: message.messageId,
    );
  }

  static void _onMessageOpenedApp(RemoteMessage message) {
    // Navigation-by-payload can be added here when needed.
  }

  static void _bindFirestoreNotifications(String uid) {
    _notificationsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .listen((snapshot) async {
          if (!_hasSeededInitialNotifications) {
            for (final doc in snapshot.docs) {
              _seededNotificationDocIds.add(doc.id);
            }
            _hasSeededInitialNotifications = true;
            return;
          }

          for (final change in snapshot.docChanges) {
            if (change.type != DocumentChangeType.added) continue;
            final doc = change.doc;
            if (_seededNotificationDocIds.contains(doc.id)) continue;
            _seededNotificationDocIds.add(doc.id);

            final data = doc.data();
            if (data == null) continue;

            final isAllowed = await _isAllowedByPreferences(uid, data);
            if (!isAllowed) continue;

            final title = (data['title'] as String?)?.trim();
            final body = (data['body'] as String?)?.trim();
            if (title == null || title.isEmpty || body == null || body.isEmpty) {
              continue;
            }

            await _localNotifications.show(
              doc.id.hashCode,
              title,
              body,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  _defaultChannel.id,
                  _defaultChannel.name,
                  channelDescription: _defaultChannel.description,
                  icon: '@mipmap/ic_launcher',
                  importance: Importance.high,
                  priority: Priority.high,
                ),
              ),
              payload: doc.id,
            );
          }
        });
  }

  static Future<bool> _isAllowedByPreferences(
    String uid,
    Map<String, dynamic> notification,
  ) async {
    final prefsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('preferences')
        .get();

    final prefs = prefsSnapshot.data() ?? <String, dynamic>{};
    final transactionAlerts = (prefs['transactionAlerts'] as bool?) ?? true;
    final budgetAlerts = (prefs['budgetAlerts'] as bool?) ?? true;

    final type = (notification['type'] as String?)?.trim().toLowerCase() ?? '';
    if (type == 'budget_alert') {
      return budgetAlerts;
    }

    final meta = (notification['meta'] as Map<String, dynamic>?) ??
        <String, dynamic>{};
    final provider = (meta['provider'] as String?)?.trim().toLowerCase() ?? '';
    if (type == 'transaction_new' || provider == 'sepay') {
      return transactionAlerts;
    }

    return true;
  }

  static Future<void> _saveToken(String? token) async {
    if (token == null || token.trim().isEmpty) return;

    if (kDebugMode) {
      debugPrint('FCM token: $token');
    }

    final uid = AuthService.currentUserId;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(token)
        .set({
      'token': token,
      'platform': 'android',
      'active': true,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
