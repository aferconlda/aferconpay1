import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final double amount;
  final DateTime date;
  final String description;
  final String type; // ex: 'revenue', 'expense', 'commission'

  TransactionModel({
    required this.id,
    required this.amount,
    required this.date,
    required this.description,
    required this.type,
  });

 factory TransactionModel.fromMap(Map<String, dynamic> data) {
    return TransactionModel(
      id: data['id'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0, 
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(), 
      description: data['description'] as String? ?? 'Descrição indisponível', 
      type: data['type'] as String? ?? 'unknown', 
    );
  }

  // Método para converter o modelo para um Map, útil para escrever no Firestore
  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'description': description,
      'type': type,
    };
  }
}
