import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final Timestamp date;
  final bool read;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    this.read = false,
  });

  // Convert a NotificationModel into a Map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'date': date,
      'read': read,
    };
  }

  // Create a NotificationModel from a Firestore document
  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    return NotificationModel(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      date: map['date'] ?? Timestamp.now(),
      read: map['read'] ?? false,
    );
  }
}
