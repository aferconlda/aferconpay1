import 'package:cloud_firestore/cloud_firestore.dart';

enum OfferType { sell, buy }

enum OfferStatus { open, closed, inProgress }

class ExchangeOffer {
  final String id;
  final String offererId; // Alterado de userId
  final String offererName; // Alterado de userDisplayName
  final OfferType type;
  final String fromCurrency;
  final String toCurrency;
  final double rate; // Alterado de exchangeRate
  final double availableAmount; // Novo
  final double minLimit; // Alterado de minAmount
  final double maxLimit; // Alterado de maxAmount
  final List<String> paymentMethods;
  final OfferStatus status;
  final Timestamp createdAt;

  ExchangeOffer({
    required this.id,
    required this.offererId,
    required this.offererName,
    required this.type,
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.availableAmount,
    required this.minLimit,
    required this.maxLimit,
    required this.paymentMethods,
    this.status = OfferStatus.open,
    required this.createdAt,
  });

  factory ExchangeOffer.fromFirestore(Map<String, dynamic> data, String id) {
    return ExchangeOffer(
      id: id,
      offererId: data['offererId'] ?? '',
      offererName: data['offererName'] ?? '',
      type: OfferType.values.firstWhere((e) => e.name == data['type'], orElse: () => OfferType.sell),
      fromCurrency: data['fromCurrency'] ?? '',
      toCurrency: data['toCurrency'] ?? '',
      rate: (data['rate'] as num?)?.toDouble() ?? 0.0,
      availableAmount: (data['availableAmount'] as num?)?.toDouble() ?? 0.0,
      minLimit: (data['minLimit'] as num?)?.toDouble() ?? 0.0,
      maxLimit: (data['maxLimit'] as num?)?.toDouble() ?? 0.0,
      paymentMethods: List<String>.from(data['paymentMethods'] ?? []),
      status: OfferStatus.values.firstWhere((e) => e.name == data['status'], orElse: () => OfferStatus.open),
      createdAt: data['createdAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'offererId': offererId,
      'offererName': offererName,
      'type': type.name,
      'fromCurrency': fromCurrency,
      'toCurrency': toCurrency,
      'rate': rate,
      'availableAmount': availableAmount,
      'minLimit': minLimit,
      'maxLimit': maxLimit,
      'paymentMethods': paymentMethods,
      'status': status.name,
      'createdAt': createdAt,
    };
  }
}
