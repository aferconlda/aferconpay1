
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String userId;
  final double amount;
  final DateTime date;
  final String description;
  final String type; // ex: 'revenue', 'expense', 'commission', 'transfer_in', 'transfer_out'

  // CAMPOS ADICIONAIS PARA SUPORTAR TRANSFERÊNCIAS
  final String? status;
  final String? senderId;
  final String? recipientId;
  final String? currency;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.date,
    required this.description,
    required this.type,
    this.status,
    this.senderId,
    this.recipientId,
    this.currency,
  });

 factory TransactionModel.fromMap(Map<String, dynamic> data) {
    return TransactionModel(
      id: data['id'] ?? '',
      userId: data['userId'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0, 
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(), 
      description: data['description'] as String? ?? 'Descrição indisponível', 
      type: data['type'] as String? ?? 'unknown', 
      status: data['status'] as String?,
      senderId: data['senderId'] as String?,
      recipientId: data['recipientId'] as String?,
      currency: data['currency'] as String?,
    );
  }

  // Método para converter o modelo para um Map, útil para escrever no Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id, // Incluído para consistência
      'userId': userId,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'description': description,
      'type': type,
      'status': status,
      'senderId': senderId,
      'recipientId': recipientId,
      'currency': currency,
    };
  }
}
