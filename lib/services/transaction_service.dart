import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class TransactionService {
  // Aponta para a região correta das Cloud Functions
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'europe-west1');

  // Para desenvolvimento, permite usar o emulador local
  TransactionService() {
    if (kDebugMode) {
      // _functions.useFunctionsEmulator('localhost', 5001);
    }
  }

  /// Garante que o utilizador está autenticado e o token está atualizado.
  Future<void> _ensureAuthenticated() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw FirebaseFunctionsException(
        code: 'unauthenticated',
        message: 'Utilizador não está autenticado.',
      );
    }
    // Força a atualização do token para evitar "race conditions"
    await currentUser.getIdToken(true);
  }

  /// Wrapper para chamar uma Cloud Function de forma segura e com gestão de erros centralizada.
  Future<HttpsCallableResult> _callFunction(
      String functionName, Map<String, dynamic> data) async {
    await _ensureAuthenticated();
    final HttpsCallable callable = _functions.httpsCallable(functionName);

    try {
      return await callable.call(data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Erro na Cloud Function [$functionName]: [${e.code}] ${e.message}');
      // A mensagem de erro já vem traduzida do nosso backend (translateErrorCode)
      // Apenas a passamos à frente.
      throw Exception(e.message ?? "Ocorreu um erro desconhecido.");
    } catch (e) {
      debugPrint('Erro inesperado ao chamar [$functionName]: $e');
      throw Exception(
          "Falha na comunicação com o servidor. Verifique a sua ligação.");
    }
  }

  /// Inicia uma transferência P2P (Pessoa-para-Pessoa).
  Future<void> p2pTransfer({
    required String recipientId,
    required double amount,
    required String description,
  }) async {
    await _callFunction('p2pTransfer', {
      'recipientId': recipientId,
      'amount': amount,
      'description': description,
    });
  }

  /// Processa um pagamento via QR Code para um comerciante ou caixa.
  Future<void> processQrPayment({
    required String recipientId,
    required double amount,
    required String description,
  }) async {
    await _callFunction('processQrPayment', {
      'recipientId': recipientId,
      'amount': amount,
      'description': description,
    });
  }
}
