import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Gera uma chave de armazenamento única para o PIN de cada utilizador.
  String _getPinKey(String userId) => 'user_pin_$userId';

  /// Guarda o PIN de 6 dígitos de forma segura para o utilizador atual e atualiza o status no Firestore.
  Future<void> savePin(String pin) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Nenhum utilizador autenticado para associar o PIN.');
    }

    final pinKey = _getPinKey(user.uid);

    // 1. Guarda o PIN localmente de forma segura com a chave específica do utilizador
    await _secureStorage.write(key: pinKey, value: pin);

    // 2. Atualiza o Firestore para indicar que o PIN foi configurado
    await _firestore.collection('users').doc(user.uid).update({
      'isTransactionPinSet': true,
    });
  }

  /// Recupera o PIN guardado para o utilizador atual. Retorna null se nenhum PIN estiver definido.
  Future<String?> getPin() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null; // Não há utilizador, não há PIN para recuperar
    }
    final pinKey = _getPinKey(user.uid);
    return await _secureStorage.read(key: pinKey);
  }

  /// Verifica se um PIN já foi definido para o utilizador atual.
  Future<bool> isPinSet() async {
    final pin = await getPin(); // Reutiliza a lógica de getPin que já trata o utilizador
    return pin != null && pin.isNotEmpty;
  }

  /// Remove o PIN guardado para o utilizador atual e atualiza o status no Firestore.
  Future<void> deletePin() async {
    final user = _auth.currentUser;
    if (user == null) {
      // Se não há utilizador, não é possível saber qual PIN apagar.
      // A lógica anterior de apagar uma chave genérica foi removida para evitar apagar o PIN de outro utilizador.
      return;
    }

    final pinKey = _getPinKey(user.uid);
    
    // 1. Remove o PIN local específico do utilizador
    await _secureStorage.delete(key: pinKey);

    // 2. Atualiza o Firestore para indicar que o PIN não está configurado
    await _firestore.collection('users').doc(user.uid).set({
      'isTransactionPinSet': false,
    }, SetOptions(merge: true));
  }
}
