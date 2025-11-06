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

  /// Submete um novo pedido de verificação de identidade para um utilizador.
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
    await _requestsCollection.add(newRequest);
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
  /// Isto garante que tanto o pedido como o perfil do utilizador são atualizados.
  Future<void> approveRequest(String requestId, String adminId) async {
    final requestDocRef = _requestsCollection.doc(requestId);

    await _db.runTransaction((transaction) async {
      // 1. Obter o pedido de verificação para encontrar o userId.
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

      // 2. Atualizar o documento do pedido de verificação.
      transaction.update(requestDocRef, {
        'status': 'approved',
        'reviewedBy': adminId,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      // 3. Atualizar o documento do utilizador.
      transaction.update(userDocRef, {
        'kycStatus': 'approved',
      });
    });
  }

  /// Rejeita um pedido de verificação numa transação atómica.
  /// Isto garante que tanto o pedido como o perfil do utilizador são atualizados.
  Future<void> rejectRequest(String requestId, String adminId, String reason) async {
    if (reason.isEmpty) {
      throw ArgumentError('A razão da rejeição não pode estar vazia.');
    }

    final requestDocRef = _requestsCollection.doc(requestId);

    await _db.runTransaction((transaction) async {
      // 1. Obter o pedido de verificação para encontrar o userId.
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

      // 2. Atualizar o documento do pedido de verificação.
      transaction.update(requestDocRef, {
        'status': 'rejected',
        'reviewedBy': adminId,
        'reviewedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
      });

       // 3. Atualizar o documento do utilizador.
      transaction.update(userDocRef, {
        'kycStatus': 'rejected',
      });
    });
  }
}
