import 'package:cloud_firestore/cloud_firestore.dart';

/// Define os estados possíveis para um pedido de verificação.
enum VerificationStatus {
  pending,   // O pedido foi enviado e aguarda revisão.
  approved,  // O pedido foi revisto e aprovado por um administrador.
  rejected,  // O pedido foi revisto e rejeitado por um administrador.
}

/// Representa um único pedido de verificação de identidade feito por um utilizador.
class VerificationRequest {
  final String id;                 // ID do documento no Firestore.
  final String userId;             // ID do utilizador que fez o pedido.
  final VerificationStatus status; // O estado atual do pedido (pendente, aprovado, rejeitado).
  final DateTime submittedAt;        // Quando o pedido foi enviado.
  final String? reviewedBy;         // ID do administrador que reviu o pedido.
  final DateTime? reviewedAt;       // Quando o pedido foi revisto.
  final String? rejectionReason;    // Motivo da rejeição (fornecido pelo administrador).

  // Adicione aqui os campos para os dados submetidos. Por exemplo:
  final String frontImageUrl;      // URL da imagem da frente do documento.
  final String backImageUrl;       // URL da imagem de trás do documento.
  final String selfieImageUrl;     // URL da selfie do utilizador com o documento.

  VerificationRequest({
    required this.id,
    required this.userId,
    required this.status,
    required this.submittedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
    required this.frontImageUrl,
    required this.backImageUrl,
    required this.selfieImageUrl,
  });

  /// Converte um documento do Firestore (Map) num objeto [VerificationRequest].
  factory VerificationRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VerificationRequest(
      id: doc.id,
      userId: data['userId'] ?? '',
      // Converte a string do status para o enum VerificationStatus.
      status: VerificationStatus.values.firstWhere(
        (e) => e.toString() == 'VerificationStatus.${data['status'] ?? 'pending'}',
        orElse: () => VerificationStatus.pending,
      ),
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
      reviewedBy: data['reviewedBy'] as String?,
      reviewedAt: data['reviewedAt'] != null ? (data['reviewedAt'] as Timestamp).toDate() : null,
      rejectionReason: data['rejectionReason'] as String?,
      frontImageUrl: data['frontImageUrl'] ?? '',
      backImageUrl: data['backImageUrl'] ?? '',
      selfieImageUrl: data['selfieImageUrl'] ?? '',
    );
  }

  /// Converte um objeto [VerificationRequest] num Map para ser guardado no Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      // Converte o enum para uma string simples (ex: 'pending').
      'status': status.toString().split('.').last,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'rejectionReason': rejectionReason,
      'frontImageUrl': frontImageUrl,
      'backImageUrl': backImageUrl,
      'selfieImageUrl': selfieImageUrl,
    };
  }
}
