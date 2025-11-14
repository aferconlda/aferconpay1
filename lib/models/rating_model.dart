
import 'package:cloud_firestore/cloud_firestore.dart';

class RatingModel {
  final String id;
  final String transactionId;
  final String raterId;
  final String ratedId;
  final double rating;
  final String? comment;
  final Timestamp createdAt;

  RatingModel({
    required this.id,
    required this.transactionId,
    required this.raterId,
    required this.ratedId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transactionId': transactionId,
      'raterId': raterId,
      'ratedId': ratedId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
    };
  }
}
