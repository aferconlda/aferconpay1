import 'package:cloud_firestore/cloud_firestore.dart';

class DepositRequestModel {
  final String id;
  final String userId;
  final double amount;
  final String status;
  final Timestamp createdAt;
  final String? userDisplayName;
  final String? userEmail;

  DepositRequestModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.userDisplayName,
    this.userEmail,
  });

  factory DepositRequestModel.fromMap(String id, Map<String, dynamic> data) {
    return DepositRequestModel(
      id: id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] as num? ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      userDisplayName: data['userDisplayName'] as String?,
      userEmail: data['userEmail'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'status': status,
      'createdAt': createdAt,
      'userDisplayName': userDisplayName,
      'userEmail': userEmail,
    };
  }
}
