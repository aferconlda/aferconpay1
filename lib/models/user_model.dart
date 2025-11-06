
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
  final double balance;
  final double floatBalance;
  final double totalCommissions;
  final double unverifiedTransactionVolume; // Adicionado
  final String? phoneNumber;
  final Timestamp? createdAt;
  final String? referralCode;
  final String? referredBy;

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
    this.balance = 0.0,
    this.floatBalance = 0.0,
    this.totalCommissions = 0.0,
    this.unverifiedTransactionVolume = 0.0, // Adicionado
    this.phoneNumber,
    this.createdAt,
    this.referralCode,
    this.referredBy,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'],
      displayName: data['displayName'],
      phoneNumber: data['phoneNumber'],
      balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
      totalCommissions: (data['totalCommissions'] as num?)?.toDouble() ?? 0.0,
      floatBalance: (data['floatBalance'] as num?)?.toDouble() ?? 0.0,
      role: data['role'] ?? 'client',
      kycStatus: KycStatus.values.firstWhere(
        (e) => e.name == data['kycStatus'],
        orElse: () => KycStatus.unverified,
      ),
      createdAt: data['createdAt'] as Timestamp?,
      referralCode: data['referralCode'],
      referredBy: data['referredBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'balance': balance,
      'totalCommissions': totalCommissions,
      'floatBalance': floatBalance,
      'role': role,
      'kycStatus': kycStatus.name,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'referralCode': referralCode,
      'referredBy': referredBy,
    };
  }
}
