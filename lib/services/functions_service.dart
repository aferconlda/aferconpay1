
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:developer';

// --- Mock HttpsCallableResult ---
// Simula a resposta que o Firebase Functions devolveria.
class MockHttpsCallableResult implements HttpsCallableResult {
  @override
  final dynamic data;

  MockHttpsCallableResult([this.data]);
}

// --- Mock FunctionsService ---
// Versão "desconectada" que simula as chamadas às Cloud Functions.

class FunctionsService {
  
  // Esta função agora é o nosso simulador principal.
  Future<HttpsCallableResult?> _callFunction(
    BuildContext context,
    String functionName,
    Map<String, dynamic> data,
    {bool isEurope = false} // O parâmetro isEurope é ignorado agora
  ) async {
    // 1. Imprime na consola para sabermos que a função foi chamada.
    log('--- SIMULANDO CLOUD FUNCTION ---');
    log('Nome da Função: $functionName');
    log('Dados Enviados: $data');
    log('--------------------------------');

    // 2. Mostra uma mensagem de sucesso na interface, como se a operação tivesse funcionado.
    // Usamos o context para garantir que podemos mostrar a SnackBar no ecrã certo.
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Operação "$functionName" simulada com sucesso!'), 
          backgroundColor: Colors.green[600],
        ),
      );
    }

    // 3. Retorna um resultado de sucesso falso para a lógica da app continuar.
    final mockResult = MockHttpsCallableResult({
      'status': 'success',
      'message': 'Operação simulada com sucesso!',
    });

    return Future.value(mockResult);
  }

  // ===================================================================
  // == MÉTODOS PÚBLICOS (permanecem iguais)
  // == Agora todos eles chamam a nossa função simulada _callFunction
  // ===================================================================

  Future<HttpsCallableResult?> createExchangeRequest({
    required BuildContext context,
    required double amountKz,
    required String targetCurrency,
    required String paymentDetails,
  }) {
    return _callFunction(context, 'createExchangeRequest', {
      'amountKz': amountKz,
      'targetCurrency': targetCurrency,
      'paymentDetails': paymentDetails,
    });
  }

  Future<HttpsCallableResult?> cancelExchangeRequest({
    required BuildContext context,
    required String requestId,
  }) {
    return _callFunction(context, 'cancelExchangeRequest', {
      'requestId': requestId,
    });
  }

  Future<HttpsCallableResult?> manageExchangeRequest({
    required BuildContext context,
    required String requestId,
    required String action,
  }) {
    return _callFunction(context, 'manageExchangeRequest', {
      'requestId': requestId,
      'action': action,
    });
  }

  Future<HttpsCallableResult?> processQrTransaction({
    required BuildContext context,
    required Map<String, dynamic> data,
  }) {
    return _callFunction(context, 'processQrTransaction', data, isEurope: true);
  }

  Future<HttpsCallableResult?> addFloatFromBalance({
    required BuildContext context,
    required double amount,
  }) {
    return _callFunction(context, 'addFloatFromBalance', {
      'amount': amount,
    });
  }

  Future<HttpsCallableResult?> requestCashierWithdrawal({
    required BuildContext context,
    required Map<String, dynamic> data,
  }) {
    return _callFunction(context, 'requestCashierWithdrawal', data, isEurope: true);
  }

  Future<HttpsCallableResult?> performP2PTransfer({
    required BuildContext context,
    required String recipientId,
    required double amount,
    required String description,
  }) {
    return _callFunction(context, 'performP2PTransfer', {
      'recipientId': recipientId,
      'amount': amount,
      'description': description,
    }, isEurope: true);
  }
}
