import 'package:cloud_firestore/cloud_firestore.dart';

class KycRequestModel {
  final String id;
  final String userId;
  final String fullName;
  final String idNumber;
  final String dateOfBirth;
  final String documentUrl;
  final String status;
  final Timestamp submittedAt;

  KycRequestModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.idNumber,
    required this.dateOfBirth,
    required this.documentUrl,
    required this.status,
    required this.submittedAt,
  });

  factory KycRequestModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return KycRequestModel(
      id: doc.id,
      // O ID do utilizador é o pai da subcoleção 'kyc_documents'
      userId: doc.reference.parent.parent!.id,
      fullName: data['fullName'] ?? '',
      idNumber: data['idNumber'] ?? '',
      dateOfBirth: data['dateOfBirth'] ?? '',
      documentUrl: data['documentUrl'] ?? '',
      status: data['status'] ?? '',
      submittedAt: data['submittedAt'] ?? Timestamp.now(),
    );
  }
}
