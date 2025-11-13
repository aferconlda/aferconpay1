import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  log("Handling a background message: ${message.messageId}");
  // We don't show a local notification here, as background messages are handled by the system.
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  // CORRECTED: Added a try-catch block to gracefully handle permission errors.
  Future<void> init() async {
    try {
      final settings = await _fcm.requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        log('Notification permission granted.');
        await _configureNotificationHandling();
        await saveTokenToDatabase();
      } else {
        log('User declined or has not accepted notification permission');
      }
    } on FirebaseException catch (e) {
      // This will catch the 'permission-blocked' error and prevent it from crashing the app.
      log('Could not request notification permission: ${e.code}');
    } catch (e) {
      // Catch any other potential errors during initialization
      log('An unexpected error occurred during notification initialization: $e');
    }
  }

  Future<void> _configureNotificationHandling() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    if (kIsWeb) {
         FirebaseMessaging.onMessage.listen((RemoteMessage message) {
            log('Got a message whilst in the foreground!');
            log('Message data: ${message.data}');

            if (message.notification != null) {
                log('Message also contained a notification: ${message.notification}');
                showNotification(message);
            }
        });
    } else {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_channel);

        await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
        );

        FirebaseMessaging.onMessage.listen(showNotification);
    }
  }


  Future<void> showNotification(RemoteMessage message) async {
    final notification = message.notification;

    // For Android, we use the FlutterLocalNotificationsPlugin.
    final android = message.notification?.android;
    if (notification != null && android != null && !kIsWeb) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: 'launch_background',
          ),
        ),
      );
    }
  }

  Future<Map<String, bool>> getUserPreferences(String userId) async {
    if (userId.isEmpty) return {};

    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists && doc.data()!.containsKey('notificationPreferences')) {
        final preferences =
            Map<String, dynamic>.from(doc.data()!['notificationPreferences']);
        return preferences.map((key, value) => MapEntry(key, value as bool));
      }
    } catch (e) {
      log('Error getting user preferences: $e');
    }
    return {};
  }

  Future<void> updateSubscription(
    String userId,
    String topic,
    bool isSubscribed,
  ) async {
    if (userId.isEmpty) return;

    try {
      if (isSubscribed) {
        await _fcm.subscribeToTopic(topic);
      } else {
        await _fcm.unsubscribeFromTopic(topic);
      }

      await _db.collection('users').doc(userId).set({
        'notificationPreferences': {topic: isSubscribed}
      }, SetOptions(merge: true));
    } catch (e) {
      log('Error updating subscription for topic $topic: $e');
    }
  }

  Future<void> saveTokenToDatabase() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // On web, we might get a different token, so we always update it.
    final token = await _fcm.getToken(); 
    if (token == null) return;

    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
      log("FCM Token saved to DB");
    } catch (e) {
      log('Error saving FCM token: $e');
    }
  }

  Future<void> removeTokenFromDatabase() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // We could also delete the token, but for this app, we'll just clear it.
      await _db.collection('users').doc(user.uid).set({
        'fcmToken': FieldValue.delete(),
      }, SetOptions(merge: true));
    } catch (e) {
      log('Error removing FCM token: $e');
    }
  }
}
