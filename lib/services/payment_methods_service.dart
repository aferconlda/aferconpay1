class PaymentMethodsService {
  // No futuro, esta lista pode vir de uma API, de configurações do utilizador, etc.
  // Por agora, centralizamo-la aqui para ser reutilizável.
  Future<List<String>> getAvailablePaymentMethods() async {
    return [
      'Transferência Bancária',
      'Depósito em Dinheiro',
      'Afrimoney',
      'Unitel Money',
      'PayPay',
      'EMIS',
    ];
  }
}
