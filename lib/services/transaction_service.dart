import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importar o serviço de autenticação
import 'package:flutter/foundation.dart'; // Import for kDebugMode

class TransactionService {
  // Get a reference to the Cloud Functions regional endpoint
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  /// Initiates a P2P (Peer-to-Peer) transfer between two users by calling a secure Cloud Function.
  ///
  /// This method no longer performs the transaction on the client side. Instead, it securely
  /// invokes the 'p2pTransfer' Cloud Function, which handles the atomic transaction,
  /// balance updates, transaction logging, and notifications on the server.
  ///
  /// This approach is more secure as it prevents client-side manipulation and centralizes
  //  critical business logic.
  ///
  /// @param recipientId The ID of the user receiving the money.
  /// @param amount The amount to transfer.
  /// @param description A description for the transaction.
  ///
  /// @throws [FirebaseFunctionsException] if the Cloud Function call fails. The exception
  /// contains a `code` and `message` that can be used to provide specific feedback to the user.
  Future<void> p2pTransfer({
    required String recipientId,
    required double amount,
    required String description,
  }) async {
    try {
      // For development, you might want to use the local functions emulator
      if (kDebugMode) {
        // To use the emulator, uncomment the following line.
        // Make sure you have the emulator running.
        // _functions.useFunctionsEmulator('localhost', 5001);
      }

      // **A SOLUÇÃO DEFINITIVA:**
      // Forçar a atualização do token de autenticação antes de chamar a função.
      // Isto resolve problemas de "race condition" em que a função é chamada antes
      // de o token de um login recente ser validado no backend.
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw FirebaseFunctionsException(
          code: 'unauthenticated',
          message: 'Utilizador não está autenticado.',
        );
      }
      await currentUser.getIdToken(true); // O 'true' força a atualização.

      // Get a callable reference to the 'p2pTransfer' function
      final HttpsCallable callable = _functions.httpsCallable('p2pTransfer');

      // Prepare the data to be sent to the function
      // The senderId is automatically added by the Cloud Function from the auth context.
      final Map<String, dynamic> data = {
        'recipientId': recipientId,
        'amount': amount,
        'description': description,
            };

      // Invoke the function and wait for the result
      final HttpsCallableResult result = await callable.call(data);

      // The result from the Cloud Function can be used for logging or further actions
      debugPrint('Cloud Function result: ${result.data}');
    } on FirebaseFunctionsException catch (e) {
      // The Cloud Function throws specific HttpsError codes which can be handled here.
      // This allows for more specific user feedback.
      // Example: 'unauthenticated', 'not-found', 'invalid-argument', 'failed-precondition'
      debugPrint('Cloud Function Error: [${e.code}] ${e.message}');

      // CORRECTED: Translated error messages to Portuguese.
      String userMessage =
          "Ocorreu um erro inesperado. Por favor, tente novamente mais tarde.";
      if (e.code == 'failed-precondition') {
        userMessage = "Saldo insuficiente para esta transferência.";
      } else if (e.code == 'not-found') {
        userMessage = "O destinatário não foi encontrado.";
      } else if (e.code == 'invalid-argument') {
        userMessage = "Os detalhes da transferência são inválidos.";
      } else if (e.code == 'unauthenticated') {
        userMessage = "A sua sessão expirou. Por favor, faça login novamente.";
      }

      throw Exception(userMessage);
    } catch (e) {
      // Catch any other unexpected errors
      debugPrint(
          'An unexpected error occurred while calling the Cloud Function: $e');
      throw Exception(
          "Falha ao iniciar a transferência. Verifique a sua ligação e tente novamente.");
    }
  }
}
