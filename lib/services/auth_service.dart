
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:afercon_pay/models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() {
    return _instance;
  }
  AuthService._internal();

  // Stream para o estado de autenticação real
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Obter o utilizador de autenticação atual
  User? get authCurrentUser => _firebaseAuth.currentUser;
  
  // Obter o utilizador atual (compatibilidade)
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  // Obter o modelo de utilizador do Firestore
  Future<UserModel?> getCurrentUserModel() async {
    final user = authCurrentUser;
    if (user == null) return null;
    return _firestoreService.getUser(user.uid);
  }

  // Métodos de autenticação existentes

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUpWithEmailAndPassword({
    required String email, 
    required String password,
    required String displayName,
    required String phoneNumber,
  }) async {
     try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      // Após a criação do usuário na autenticação, crie o documento no Firestore
      if (userCredential.user != null) {
        await _firestoreService.createUser(
          userCredential.user!.uid,
          displayName,
          email,
          phoneNumber
        );
         // Opcional: Atualizar o display name no próprio objeto de autenticação do Firebase
        await userCredential.user!.updateDisplayName(displayName);
      }

      return userCredential;

    } on FirebaseAuthException {
      // Tratar exceções específicas do Firebase Auth (e.g., email-already-in-use)
      rethrow; // Relança a exceção para a UI tratar
    } catch (e) {
      // Tratar outros erros
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<UserCredential> signInWithPhoneCredential(PhoneAuthCredential credential) async {
    return _firebaseAuth.signInWithCredential(credential);
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
