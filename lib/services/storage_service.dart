import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadPaymentProof(File imageFile, String transactionId) async {
    try {
      final ref = _storage.ref().child('payment_proofs').child('$transactionId.jpg');
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> uploadDisputeProof(File imageFile, String transactionId) async {
    try {
      // Use a timestamp to ensure unique file names for each proof image
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('dispute_proofs').child(transactionId).child('$timestamp.jpg');

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }
}
