import 'package:cloud_firestore/cloud_firestore.dart';

enum P2PTransactionStatus { 
  awaitingPayment,
  paymentSent,
  paymentConfirmed,
  cancelled,
  disputed 
}

class P2PTransaction {
  final String id;
  final String offerId;
  final String sellerId;
  final String buyerId;
  final double amountAOA;
  final double amountOtherCurrency; // e.g., USD
  final double exchangeRate;
  final P2PTransactionStatus status;
  final Timestamp createdAt;
  final String? paymentProofUrl; // Link para a imagem do comprovativo

  P2PTransaction({
    required this.id,
    required this.offerId,
    required this.sellerId,
    required this.buyerId,
    required this.amountAOA,
    required this.amountOtherCurrency,
    required this.exchangeRate,
    required this.status,
    required this.createdAt,
    this.paymentProofUrl,
  });


  factory P2PTransaction.fromFirestore(Map<String, dynamic> data, String id) {
    return P2PTransaction(
      id: id,
      offerId: data['offerId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      buyerId: data['buyerId'] ?? '',
      amountAOA: (data['amountAOA'] as num?)?.toDouble() ?? 0.0,
      amountOtherCurrency: (data['amountOtherCurrency'] as num?)?.toDouble() ?? 0.0,
      exchangeRate: (data['exchangeRate'] as num?)?.toDouble() ?? 0.0,
      status: P2PTransactionStatus.values.firstWhere((e) => e.name == data['status'], orElse: () => P2PTransactionStatus.awaitingPayment),
      createdAt: data['createdAt'] as Timestamp,
      paymentProofUrl: data['paymentProofUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'offerId': offerId,
      'sellerId': sellerId,
      'buyerId': buyerId,
      'amountAOA': amountAOA,
      'amountOtherCurrency': amountOtherCurrency,
      'exchangeRate': exchangeRate,
      'status': status.name,
      'createdAt': createdAt,
      'paymentProofUrl': paymentProofUrl,
    };
  }
}
