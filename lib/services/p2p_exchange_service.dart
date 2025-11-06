import 'package:afercon_pay/models/dispute_message_model.dart';
import 'package:afercon_pay/models/exchange_offer_model.dart';
import 'package:afercon_pay/models/p2p_transaction_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class P2PExchangeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late final CollectionReference<ExchangeOffer> _offersRef;
  late final CollectionReference<P2PTransaction> _transactionsRef;

  P2PExchangeService() {
    _offersRef = _firestore.collection('p2p_offers').withConverter<ExchangeOffer>(
      fromFirestore: (snapshots, _) => ExchangeOffer.fromFirestore(snapshots.data()!,
       snapshots.id),
      toFirestore: (offer, _) => offer.toFirestore(),
    );
    _transactionsRef = _firestore.collection('p2p_transactions').withConverter<P2PTransaction>(
      fromFirestore: (snapshots, _) => P2PTransaction.fromFirestore(snapshots.data()!, snapshots.id),
      toFirestore: (transaction, _) => transaction.toFirestore(),
    );
  }

  Stream<List<ExchangeOffer>> getOpenOffers() {
    return _offersRef.where('status', isEqualTo: 'open').snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> createOffer(ExchangeOffer offer) async {
    try {
      await _offersRef.add(offer);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> createTransaction(P2PTransaction transaction) async {
    try {
      final docRef = await _transactionsRef.add(transaction);
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  Stream<P2PTransaction> getTransactionStream(String transactionId) {
    return _transactionsRef.doc(transactionId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        throw Exception('Transação não encontrada!');
      }
      return snapshot.data()!;
    });
  }

  Future<void> updateTransactionStatus(String transactionId, P2PTransactionStatus newStatus, {String? paymentProofUrl}) async {
    try {
      final Map<String, dynamic> dataToUpdate = {
        'status': newStatus.name,
      };

      if (paymentProofUrl != null) {
        dataToUpdate['paymentProofUrl'] = paymentProofUrl;
      }

      await _transactionsRef.doc(transactionId).update(dataToUpdate);
    } catch (e) {
      rethrow;
    }
  }

  // Gets the stream of dispute messages for a specific transaction.
  Stream<List<DisputeMessage>> getDisputeMessagesStream(String transactionId) {
    final messagesRef = _transactionsRef.doc(transactionId).collection('dispute_messages').orderBy('timestamp', descending: true);

    return messagesRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => DisputeMessage.fromFirestore(doc)).toList();
    });
  }

  // Sends a dispute message and adds it to the transaction's subcollection.
  Future<void> sendDisputeMessage(String transactionId, String text, String senderId, {String? imageUrl}) async {
    if (text.isEmpty && imageUrl == null) return; // Avoid sending empty messages

    final messagesRef = _transactionsRef.doc(transactionId).collection('dispute_messages');

    final newMessage = DisputeMessage(
      messageId: messagesRef.doc().id, // Firestore generates the ID
      senderId: senderId,
      text: text,
      imageUrl: imageUrl,
      timestamp: Timestamp.now(),
    );

    await messagesRef.add(newMessage.toFirestore());
  }
}
