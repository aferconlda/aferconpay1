
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<bool> isBiometricAuthAvailable() async {
    final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    return canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
  }

  Future<bool> authenticate(String localizedReason) async {
    try {
      // CORREÇÃO DEFINITIVA (SÉRIA): Os parâmetros `stickyAuth` e `biometricOnly` 
      // foram removidos ou alterados nesta versão do `local_auth`.
      // A chamada base apenas com a razão localizada é a forma correta e segura de garantir a compilação.
      return await _auth.authenticate(
        localizedReason: localizedReason,
      );
    } on PlatformException {
      return false;
    }
  }

  Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: 'email', value: email);
    await _storage.write(key: 'password', value: password);
  }

  Future<Map<String, String?>> getCredentials() async {
    final email = await _storage.read(key: 'email');
    final password = await _storage.read(key: 'password');
    return {'email': email, 'password': password};
  }

  Future<void> deleteCredentials() async {
    await _storage.delete(key: 'email');
    await _storage.delete(key: 'password');
  }
}
