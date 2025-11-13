import 'package:cloud_firestore/cloud_firestore.dart';

enum KycStatus { none, unverified, pending, approved, rejected }

class PaymentDetail {
  final String method;
  final String details;

  PaymentDetail({required this.method, required this.details});

  factory PaymentDetail.fromMap(Map<String, dynamic> map) {
    return PaymentDetail(
      method: map['method'] ?? '',
      details: map['details'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'method': method,
      'details': details,
    };
  }
}

class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String role;
  final bool isEmailVerified;
  final String authProvider;
  final Timestamp? lastLogin;
  final KycStatus kycStatus;
  final List<PaymentDetail> paymentDetails;
  final Map<String, double> balance; // Mantido como Mapa para o futuro
  final double floatBalance;
  final double totalCommissions;
  final double unverifiedTransactionVolume;
  final String? phoneNumber;
  final Timestamp? createdAt;
  final String? referralCode;
  final String? referredBy;
  final double averageRating;
  final int totalRatings;
  final double completionRate;
  final bool hasTransactionPin; // NOVO CAMPO ADICIONADO

  // GETTER DE COMPATIBILIDADE (ADICIONADO)
  double get aoaBalance => balance['AOA'] ?? 0.0;

  UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.role = 'client',
    this.isEmailVerified = false,
    this.authProvider = 'email',
    this.lastLogin,
    this.kycStatus = KycStatus.unverified,
    this.paymentDetails = const [],
    this.balance = const {'AOA': 0.0},
    this.floatBalance = 0.0,
    this.totalCommissions = 0.0,
    this.unverifiedTransactionVolume = 0.0,
    this.phoneNumber,
    this.createdAt,
    this.referralCode,
    this.referredBy,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.completionRate = 100.0,
    this.hasTransactionPin = false, // VALOR PADRÃO
  });

  // MÉTODO fromMap RESTAURADO E MELHORADO
  factory UserModel.fromMap(Map<String, dynamic> data) {
    final paymentDetailsList = data['paymentDetails'] as List<dynamic>?;
    final details = paymentDetailsList != null
        ? paymentDetailsList.map((d) => PaymentDetail.fromMap(d as Map<String, dynamic>)).toList()
        : <PaymentDetail>[];
    
    Map<String, double> balanceMap;
    if (data['balance'] is double) { // Lida com o formato antigo
      balanceMap = {'AOA': (data['balance'] as num).toDouble()};
    } else if (data['balance'] is Map) { // Lida com o formato novo
      balanceMap = (data['balance'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
    } else { // Fallback
      balanceMap = {'AOA': 0.0};
    }

    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      role: data['role'] ?? 'client',
      isEmailVerified: data['isEmailVerified'] ?? false,
      authProvider: data['authProvider'] ?? 'email',
      lastLogin: data['lastLogin'] as Timestamp?,
      kycStatus: KycStatus.values.firstWhere(
        (e) => e.name == data['kycStatus'],
        orElse: () => KycStatus.unverified,
      ),
      paymentDetails: details,
      balance: balanceMap,
      floatBalance: (data['floatBalance'] as num?)?.toDouble() ?? 0.0,
      totalCommissions: (data['totalCommissions'] as num?)?.toDouble() ?? 0.0,
      unverifiedTransactionVolume: (data['unverifiedTransactionVolume'] as num?)?.toDouble() ?? 0.0,
      phoneNumber: data['phoneNumber'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
      referralCode: data['referralCode'] as String?,
      referredBy: data['referredBy'] as String?,
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: (data['totalRatings'] as num?)?.toInt() ?? 0,
      completionRate: (data['completionRate'] as num?)?.toDouble() ?? 100.0,
      hasTransactionPin: data['hasTransactionPin'] ?? false, // LER O NOVO CAMPO
    );
  }

  // MÉTODO toMap RESTAURADO
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
      'isEmailVerified': isEmailVerified,
      'authProvider': authProvider,
      'lastLogin': lastLogin,
      'kycStatus': kycStatus.name,
      'paymentDetails': paymentDetails.map((pd) => pd.toMap()).toList(),
      'balance': balance,
      'floatBalance': floatBalance,
      'totalCommissions': totalCommissions,
      'unverifiedTransactionVolume': unverifiedTransactionVolume,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'referralCode': referralCode,
      'referredBy': referredBy,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'completionRate': completionRate,
      'hasTransactionPin': hasTransactionPin, // SALVAR O NOVO CAMPO
    };
  }

  // Métodos para o P2PExchangeService (com withConverter)
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
     final data = snapshot.data();
     if(data == null) throw Exception("User data is null!");
     return UserModel.fromMap(data)..uid;
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }
}
