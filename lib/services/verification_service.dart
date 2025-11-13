
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/verification_request.dart';

/// Gere todas as operações relacionadas com os pedidos de verificação de identidade.
class VerificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late final CollectionReference<VerificationRequest> _requestsCollection;

  VerificationService() {
    _requestsCollection = _db.collection('verificationRequests').withConverter<VerificationRequest>(
      fromFirestore: (snapshot, _) => VerificationRequest.fromFirestore(snapshot),
      toFirestore: (request, _) => request.toFirestore(),
    );
  }

  /// Submete um novo pedido de verificação e atualiza o estado do utilizador para 'pending'.
  Future<void> submitRequest({
    required String userId,
    required String frontImageUrl,
    required String backImageUrl,
    required String selfieImageUrl,
  }) async {
    final newRequest = VerificationRequest(
      id: '', // O ID será gerado pelo Firestore.
      userId: userId,
      status: VerificationStatus.pending,
      submittedAt: DateTime.now(),
      frontImageUrl: frontImageUrl,
      backImageUrl: backImageUrl,
      selfieImageUrl: selfieImageUrl,
    );

    final userDocRef = _db.collection('users').doc(userId);
    final newRequestDocRef = _requestsCollection.doc();

    // Executa a criação do pedido e a atualização do utilizador numa transação.
    await _db.runTransaction((transaction) async {
      // 1. Atualiza o estado KYC do utilizador para 'pending'.
      transaction.update(userDocRef, {'kycStatus': 'pending'});

      // 2. Adiciona o novo pedido de verificação.
      transaction.set(newRequestDocRef, newRequest);
    });
  }

  /// Obtém um stream da lista de pedidos de verificação com um status específico.
  Stream<List<VerificationRequest>> getRequestsByStatus(VerificationStatus status) {
    final statusString = status.toString().split('.').last;
    return _requestsCollection
        .where('status', isEqualTo: statusString)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Encontra o ID de um pedido de verificação pendente para um determinado utilizador.
  /// Retorna o ID do documento (requestId) se encontrado, caso contrário, retorna nulo.
  Future<String?> findPendingRequestIdForUser(String userId) async {
    final querySnapshot = await _requestsCollection
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.id;
    }
    return null;
  }

  /// Aprova um pedido de verificação numa transação atómica.
  Future<void> approveRequest(String requestId, String adminId) async {
    final requestDocRef = _requestsCollection.doc(requestId);

    await _db.runTransaction((transaction) async {
      final requestSnapshot = await transaction.get(requestDocRef);
      if (!requestSnapshot.exists) {
        throw Exception("O pedido de verificação não foi encontrado.");
      }
      final requestData = requestSnapshot.data();
      if (requestData == null) {
        throw Exception("Os dados do pedido de verificação são inválidos.");
      }
      final userId = requestData.userId;
      final userDocRef = _db.collection('users').doc(userId);

      transaction.update(requestDocRef, {
        'status': 'approved',
        'reviewedBy': adminId,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(userDocRef, {'kycStatus': 'approved'});
    });
  }

  /// Rejeita um pedido de verificação numa transação atómica.
  Future<void> rejectRequest(String requestId, String adminId, String reason) async {
    if (reason.isEmpty) {
      throw ArgumentError('A razão da rejeição não pode estar vazia.');
    }

    final requestDocRef = _requestsCollection.doc(requestId);

    await _db.runTransaction((transaction) async {
      final requestSnapshot = await transaction.get(requestDocRef);
      if (!requestSnapshot.exists) {
        throw Exception("O pedido de verificação não foi encontrado.");
      }
      final requestData = requestSnapshot.data();
      if (requestData == null) {
        throw Exception("Os dados do pedido de verificação são inválidos.");
      }
      final userId = requestData.userId;
      final userDocRef = _db.collection('users').doc(userId);

      transaction.update(requestDocRef, {
        'status': 'rejected',
        'reviewedBy': adminId,
        'reviewedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
      });

      transaction.update(userDocRef, {'kycStatus': 'rejected'});
    });
  }
}
