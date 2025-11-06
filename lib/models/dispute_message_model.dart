import 'package:cloud_firestore/cloud_firestore.dart';

class DisputeMessage {
  final String messageId;
  final String senderId;
  final String text;
  final String? imageUrl;
  final Timestamp timestamp;

  DisputeMessage({
    required this.messageId,
    required this.senderId,
    required this.text,
    this.imageUrl,
    required this.timestamp,
  });

  factory DisputeMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DisputeMessage(
      messageId: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      imageUrl: data['imageUrl'] as String?,
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': timestamp,
    };
  }
}
