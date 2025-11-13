import 'dart:async';
import 'package:afercon_pay/services/notification_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:afercon_pay/models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFunctions _firebaseFunctions = FirebaseFunctions.instanceFor(region: 'europe-west1');
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();

  static final AuthService _instance = AuthService._internal();
  factory AuthService() {
    return _instance;
  }
  AuthService._internal();

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get authCurrentUser => _firebaseAuth.currentUser;

  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  Future<UserModel?> getCurrentUserModel() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return _firestoreService.getUser(user.uid);
  }

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    final userCredential = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    if (userCredential.user != null) {
      await _notificationService.saveTokenToDatabase();
    }
    return userCredential;
  }

  // REPARADO: Adicionado o parâmetro referralCode
  Future<void> signUpWithPhoneNumberCheck({
    required String email,
    required String password,
    required String displayName,
    required String phoneNumber,
    required String nif,
    String? referralCode, // Parâmetro opcional para o código de convite
  }) async {
    User? user;
    try {
      // Passo 1: Criar o utilizador na autenticação
      final UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = userCredential.user;

      if (user == null) {
        throw Exception('A criação do utilizador na autenticação falhou.');
      }

      // Passo 2: Atualizar o nome de exibição
      await user.updateDisplayName(displayName);

      // Passo 3: Chamar a Cloud Function com todos os dados, incluindo o código de convite
      final callable = _firebaseFunctions.httpsCallable('createUserAccount');
      final String internationalPhoneNumber = '+244$phoneNumber';

      await callable.call(<String, dynamic>{
        'uid': user.uid,
        'email': email,
        'phoneNumber': internationalPhoneNumber,
        'displayName': displayName,
        'nif': nif,
        'referralCode': referralCode, // Enviar o código para a Cloud Function
      });

    } catch (e) {
      // BLOCO DE REVERSÃO: Se qualquer um dos passos acima falhar...
      if (user != null) {
        // ... apaga o utilizador da autenticação para que se possa tentar registar novamente.
        await user.delete();
      }
      // Re-lança a exceção para que o ecrã de registo a possa apanhar e mostrar um erro.
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _notificationService.removeTokenFromDatabase();
    await _firebaseAuth.signOut();
  }

  Future<UserCredential> signInWithPhoneCredential(PhoneAuthCredential credential) async {
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    if (userCredential.user != null) {
      await _notificationService.saveTokenToDatabase();
    }
    return userCredential;
  }

  Future<void> sendEmailVerification() async {
    final user = authCurrentUser;
    if (user != null && !user.emailVerified) {
      return user.sendEmailVerification();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    return _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _firebaseAuth.setLanguageCode('pt');

    return _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
  }
}
