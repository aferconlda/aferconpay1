import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../providers/notification_provider.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationProvider? _notificationProvider;

  void setNotificationProvider(NotificationProvider provider) {
    _notificationProvider = provider;
  }

  Future<void> initialize() async {
    if (kIsWeb) return;

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'Notificações Importantes', // title
      description: 'Este canal é usado para notificações importantes.', // description
      importance: Importance.max,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotificationsPlugin.initialize(initializationSettings);
  }

  void showNotification(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && !kIsWeb) {
      _localNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'Notificações Importantes',
            channelDescription: 'Este canal é usado para notificações importantes.',
            icon: android?.smallIcon,
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
      _notificationProvider?.setUnreadStatus(true);
    }
  }

  void clearAppBadge() {}

  Future<void> updateSubscription(
      String userId, String topic, bool isSubscribed) async {
    try {
      final topicName = topic.toLowerCase().replaceAll(' ', '_');
      if (isSubscribed) {
        await _firebaseMessaging.subscribeToTopic(topicName);
      } else {
        await _firebaseMessaging.unsubscribeFromTopic(topicName);
      }
      await _firestore.collection('users').doc(userId).set({
        'notification_preferences': {
          topicName: isSubscribed, // CORRIGIDO
        }
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, bool>> getUserPreferences(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data()!.containsKey('notification_preferences')) {
        final preferences =
            doc.data()!['notification_preferences'] as Map<String, dynamic>;
        return preferences.map((key, value) => MapEntry(key, value as bool));
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<void> syncSubscriptionsOnLogin(String userId) async {
    final preferences = await getUserPreferences(userId);
    final topics = ['transactions', 'security', 'promotions'];

    for (String topic in topics) {
      final bool shouldBeSubscribed =
          preferences[topic] ?? (topic != 'promotions');

      if (shouldBeSubscribed) {
        await _firebaseMessaging.subscribeToTopic(topic);
      } else {
        await _firebaseMessaging.unsubscribeFromTopic(topic);
      }

      await updateSubscription(userId, topic, shouldBeSubscribed);
    }
  }
}
