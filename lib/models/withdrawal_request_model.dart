import 'package:cloud_firestore/cloud_firestore.dart';

class WithdrawalRequestModel {
  final String id;
  final String transactionId; // Adicionado
  final String userId;
  final String beneficiaryName;
  final String iban;
  final double amount;
  final double fee;
  final double totalDebited;
  final String status;
  final Timestamp createdAt;
  final String? userDisplayName;
  final String? userEmail;

  WithdrawalRequestModel({
    required this.id,
    required this.transactionId, // Adicionado
    required this.userId,
    required this.beneficiaryName,
    required this.iban,
    required this.amount,
    required this.fee,
    required this.totalDebited,
    required this.status,
    required this.createdAt,
    this.userDisplayName,
    this.userEmail,
  });

  factory WithdrawalRequestModel.fromMap(String id, Map<String, dynamic> data) {
    return WithdrawalRequestModel(
      id: id,
      transactionId: data['transactionId'] ?? '', // Adicionado
      userId: data['userId'] ?? '',
      beneficiaryName: data['beneficiaryName'] ?? '',
      iban: data['iban'] ?? '',
      amount: (data['amount'] as num? ?? 0).toDouble(),
      fee: (data['fee'] as num? ?? 0).toDouble(),
      totalDebited: (data['totalDebited'] as num? ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      userDisplayName: data['userDisplayName'] as String?,
      userEmail: data['userEmail'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'userId': userId,
      'beneficiaryName': beneficiaryName,
      'iban': iban,
      'amount': amount,
      'fee': fee,
      'totalDebited': totalDebited,
      'status': status,
      'createdAt': createdAt,
      'userDisplayName': userDisplayName,
      'userEmail': userEmail,
    };
  }
}
