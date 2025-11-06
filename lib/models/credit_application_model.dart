import 'package:cloud_firestore/cloud_firestore.dart';

class CreditApplicationModel {
  final String? id;
  final String userId;
  final double amount;
  final int months;
  final String reason;
  final String status; // pending, approved, rejected
  final String creditType; // personal, business
  final Timestamp createdAt;

  CreditApplicationModel({
    this.id,
    required this.userId,
    required this.amount,
    required this.months,
    required this.reason,
    required this.status,
    required this.creditType,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'months': months,
      'reason': reason,
      'status': status,
      'creditType': creditType,
      'createdAt': createdAt,
    };
  }

  factory CreditApplicationModel.fromMap(String id, Map<String, dynamic> map) {
    return CreditApplicationModel(
      id: id,
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      months: map['months'] ?? 0,
      reason: map['reason'] ?? '',
      status: map['status'] ?? '',
      creditType: map['creditType'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }
}
