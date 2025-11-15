import 'package:cloud_functions/cloud_functions.dart';

class CashierService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');

  /// Adiciona fundos ao saldo flutuante do caixa a partir do seu saldo principal.
  Future<Map<String, dynamic>> addFloatFromBalance(double amount) async {
    try {
      final callable = _functions.httpsCallable('addFloat');
      final result = await callable.call({'amount': amount});
      return {'status': 'success', 'message': result.data?['message'] ?? 'Operação concluída com sucesso.'};
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Ocorreu um erro ao comunicar com o servidor.');
    } catch (e) {
      throw Exception('Ocorreu um erro inesperado ao adicionar fundos ao float.');
    }
  }

  /// Move fundos do saldo flutuante do caixa para o seu saldo principal.
  Future<void> withdrawFloatToBalance(double amount) async {
    try {
      final callable = _functions.httpsCallable('withdrawFloatToBalance');
      await callable.call({'amount': amount});
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Ocorreu um erro ao comunicar com o servidor.');
    } catch (e) {
      throw Exception('Ocorreu um erro inesperado.');
    }
  }

  /// Processa um depósito em numerário para um cliente.
  Future<Map<String, dynamic>> processClientDeposit({required String clientId, required double amount}) async {
    try {
      final callable = _functions.httpsCallable('processClientDeposit');
      final result = await callable.call({
        'clientId': clientId,
        'amount': amount,
      });
      return {'status': 'success', 'message': result.data?['message'] ?? 'Depósito processado com sucesso.'};
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Ocorreu um erro ao processar o depósito.');
    } catch (e) {
      throw Exception('Ocorreu um erro inesperado durante o depósito.');
    }
  }

  /// Processa um levantamento em numerário para um cliente.
  Future<Map<String, dynamic>> processClientWithdrawal({required String clientId, required double amount}) async {
    try {
      final callable = _functions.httpsCallable('processClientWithdrawal');
      final result = await callable.call({
        'clientId': clientId,
        'amount': amount,
      });
      return {'status': 'success', 'message': result.data?['message'] ?? 'Levantamento processado com sucesso.'};
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Ocorreu um erro ao processar o levantamento.');
    } catch (e) {
      throw Exception('Ocorreu um erro inesperado durante o levantamento.');
    }
  }

  // --- MÉTODOS ADICIONADOS PARA CORRIGIR ERROS DE COMPILAÇÃO ---

  Future<void> processQrTransaction(Map<String, dynamic> data) async {
    // Esta função foi substituída pela lógica em CashierConfirmationScreen
    // e será removida ou refatorada no futuro.
    throw UnimplementedError('A função processQrTransaction não está mais em uso.');
  }

  Future<void> requestCashierWithdrawal(Map<String, dynamic> data) async {
    // Lógica para solicitar levantamento de caixa será implementada futuramente.
    throw UnimplementedError('A função requestCashierWithdrawal ainda não foi implementada.');
  }

  Future<void> withdrawCommissionToBalance(double amount) async {
    // Lógica para levantar comissão para saldo será implementada futuramente.
    throw UnimplementedError('A função withdrawCommissionToBalance ainda não foi implementada.');
  }
}
