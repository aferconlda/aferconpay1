import 'package:cloud_firestore/cloud_firestore.dart';

class CommissionTransactionModel {
  final String id;
  final double amount;
  final DateTime date;
  final String? originalRequestId; // FIX: Made nullable

  CommissionTransactionModel({
    required this.id,
    required this.amount,
    required this.date,
    this.originalRequestId, // FIX: Made optional
  });

  // Construtor para criar uma instância a partir de um Map
  factory CommissionTransactionModel.fromMap(String id, Map<String, dynamic> data) {
    return CommissionTransactionModel(
      id: id,
      amount: (data['amount'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      // FIX: Safely parse as nullable String
      originalRequestId: data['originalRequestId'] as String?,
    );
  }

  // Método para converter a instância num Map para o Firestore
  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'originalRequestId': originalRequestId,
    };
  }
}
