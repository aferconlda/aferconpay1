import 'package:cloud_firestore/cloud_firestore.dart';

class CreditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionPath = 'credit_requests';

  // FIX: Adjusted personal interest rate to 3%
  static const double personalInterestRate = 0.03; // 3% ao mês
  static const double businessInterestRate = 0.035; // 3.5% ao mês

  // Converte o mapa de um pedido para a estrutura de dados do Firestore.
  Map<String, dynamic> _creditRequestToMap(Map<String, dynamic> request) {
    return {
      'userId': request['userId'],
      'fullName': request['fullName'],
      'reason': request['reason'],
      'amount': request['amount'],
      'termInMonths': request['termInMonths'],
      'type': request['type'], // 'personal' ou 'business'
      'status': 'pending', // pending, approved, rejected, paid
      'monthlyPayment': request['monthlyPayment'],
      'interestRate': request['interestRate'],
      'totalRepayment': request['totalRepayment'],
      'totalInterest': request['totalInterest'],
      'applicationDate': FieldValue.serverTimestamp(),
    };
  }

  // Calcula os detalhes de um empréstimo.
  Map<String, double> calculateLoanDetails(double amount, int termInMonths, String type) {
    final double rate = type == 'personal' ? personalInterestRate : businessInterestRate;
    
    if (rate <= 0 || termInMonths <= 0) {
         final monthlyPayment = termInMonths > 0 ? amount / termInMonths : amount;
         final totalRepayment = amount;
         const totalInterest = 0.0;
         return {
            'monthlyPayment': monthlyPayment,
            'totalRepayment': totalRepayment,
            'totalInterest': totalInterest,
            'interestRate': 0.0,
         };
    }

    // Using the formula for annuity payment: PMT = P * [r(1+r)^n] / [(1+r)^n – 1]
    // Where: P = principal loan amount, r = monthly interest rate, n = number of months
    final double monthlyRate = rate;
    final double factor = (1 + monthlyRate) * termInMonths;
    final pmt = amount * (monthlyRate * factor) / (factor - 1);
    
    final totalRepayment = pmt * termInMonths;
    final totalInterest = totalRepayment - amount;

    // Check for non-finite values and fallback to simple interest if calculation fails
    if (!pmt.isFinite || !totalRepayment.isFinite) {
        final simpleInterestTotal = amount * (1 + monthlyRate * termInMonths);
        return {
          'monthlyPayment': simpleInterestTotal / termInMonths,
          'totalRepayment': simpleInterestTotal,
          'totalInterest': simpleInterestTotal - amount,
          'interestRate': rate, 
        };
    }

    return {
      'monthlyPayment': pmt,
      'totalRepayment': totalRepayment,
      'totalInterest': totalInterest,
      'interestRate': rate, 
    };
  }

  // Submete um novo pedido de crédito.
  Future<void> applyForCredit(Map<String, dynamic> applicationData) async {
    try {
      final calculation = calculateLoanDetails(
        applicationData['amount'],
        applicationData['termInMonths'],
        applicationData['type'],
      );
      final fullRequest = {...applicationData, ...calculation};
      await _firestore.collection(_collectionPath).add(_creditRequestToMap(fullRequest));
    } catch (e) {
      rethrow;
    }
  }

  // Obtém o histórico de crédito de um utilizador.
  Stream<QuerySnapshot> getCreditHistory(String userId) {
    return _firestore
        .collection(_collectionPath)
        .where('userId', isEqualTo: userId)
        .orderBy('applicationDate', descending: true)
        .snapshots();
  }

  // --- Funções para o Painel de Administração ---

  /// Obtém todos os pedidos de crédito pendentes para revisão.
  Stream<QuerySnapshot> getPendingCreditApplications() {
    return _firestore
        .collection(_collectionPath)
        .where('status', isEqualTo: 'pending')
        .orderBy('applicationDate', descending: true)
        .snapshots();
  }

  /// Atualiza o estado de um pedido de crédito específico.
  Future<void> updateCreditApplicationStatus(String applicationId, String newStatus) async {
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(applicationId)
          .update({'status': newStatus});
    } catch (e) {
      // Em produção, use um serviço de logging.
      rethrow;
    }
  }
}
