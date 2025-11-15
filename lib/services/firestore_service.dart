import 'dart:async';
import 'package:afercon_pay/models/transaction_model.dart';
import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/models/notification_model.dart';
import 'package:afercon_pay/models/credit_application_model.dart';
import 'package:afercon_pay/models/rating_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:afercon_pay/models/deposit_request_model.dart';
import 'package:afercon_pay/models/withdrawal_request_model.dart';
import 'package:afercon_pay/models/commission_transaction_model.dart';

class FirestoreService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // Singleton pattern
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() {
    return _instance;
  }
  FirestoreService._internal();

  // Adicionado para suportar a atualização do ecrã de verificação
  Future<void> updateUserFields(String userId, Map<String, dynamic> data) {
    return db.collection('users').doc(userId).update(data);
  }

  // ===================================================================
  // == RATING METHODS
  // ===================================================================

  Future<void> submitRating({
    required String transactionId,
    required String raterId,
    required String ratedId,
    required double rating,
    String? comment,
  }) async {
    final ratedUserRef = db.collection('users').doc(ratedId);
    final ratingRef = db.collection('p2p_ratings').doc();

    return db.runTransaction((transaction) async {
      final ratedUserSnapshot = await transaction.get(ratedUserRef);

      if (!ratedUserSnapshot.exists) {
        throw Exception("Utilizador a ser avaliado não encontrado.");
      }

      final ratedUser = UserModel.fromMap(ratedUserSnapshot.data()!);

      final oldTotalRatingPoints = ratedUser.averageRating * ratedUser.totalRatings;
      final newTotalRatings = ratedUser.totalRatings + 1;
      final newAverageRating = (oldTotalRatingPoints + rating) / newTotalRatings;

      transaction.update(ratedUserRef, {
        'averageRating': newAverageRating,
        'totalRatings': newTotalRatings,
      });

      final newRating = RatingModel(
        id: ratingRef.id,
        transactionId: transactionId,
        raterId: raterId,
        ratedId: ratedId,
        rating: rating,
        comment: comment,
        createdAt: Timestamp.now(),
      );
      transaction.set(ratingRef, newRating.toMap());
    });
  }

  // ===================================================================
  // == USER METHODS
  // ===================================================================

  Future<void> createUser(String userId, String displayName, String email, String phoneNumber, {String? referredBy}) async {
    final referralCode = _generateReferralCode(displayName);
    final user = UserModel(
      uid: userId,
      displayName: displayName,
      email: email,
      phoneNumber: phoneNumber,
      kycStatus: KycStatus.unverified,
      createdAt: Timestamp.now(),
      referralCode: referralCode,
      referredBy: referredBy,
    );

    return db.collection('users').doc(userId).set(user.toMap());
  }

  Stream<UserModel> getUserStream(String userId) {
    return db.collection('users').doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromMap(snapshot.data()!);
      } else {
        throw Exception("User document not found!");
      }
    });
  }

  Future<UserModel?> getUser(String userId) async {
    final snapshot = await db.collection('users').doc(userId).get();
    if (snapshot.exists && snapshot.data() != null) {
      return UserModel.fromMap(snapshot.data()!);
    } else {
      return null;
    }
  }
  
  Future<void> updateUserData(String userId, Map<String, dynamic> data) {
    return db.collection('users').doc(userId).update(data);
  }

  Stream<List<UserModel>> getAllUsersStream() {
    return db.collection('users').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
  }

  Future<void> updateUserKycStatus(String userId, KycStatus newStatus, {String? rejectionReason}) async {
    Map<String, dynamic> data = {
      'kycStatus': newStatus.name,
      'kycRejectionReason': rejectionReason,
    };
    return db.collection('users').doc(userId).update(data);
  }

  Future<void> updateUserRole(String userId, String newRole) {
    return db.collection('users').doc(userId).update({'role': newRole});
  }

  Stream<List<UserModel>> getUsersByKycStatusStream(KycStatus status) {
    return db
        .collection('users')
        .where('kycStatus', isEqualTo: status.name)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
  }

  Future<UserModel?> findUserByPhone(String phoneNumber) async {
    final querySnapshot = await db
        .collection('users')
        .where('phoneNumber', isEqualTo: phoneNumber)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return UserModel.fromMap(querySnapshot.docs.first.data());
    }
    return null;
  }

  Future<UserModel?> findUserByContact(String contact) async {
    var querySnapshot = await db
        .collection('users')
        .where('phoneNumber', isEqualTo: contact)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      querySnapshot = await db
          .collection('users')
          .where('email', isEqualTo: contact)
          .limit(1)
          .get();
    }

    if (querySnapshot.docs.isNotEmpty) {
      return UserModel.fromMap(querySnapshot.docs.first.data());
    }
    return null;
  }

    // ===================================================================
  // == TRANSACTION METHODS
  // ===================================================================

  Stream<List<TransactionModel>> getTransactionsStream(String userId) {
    return db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap(doc.data()))
            .toList());
  }
  
  Future<void> addTransaction(String userId, TransactionModel transaction) async {
    final docRef = db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc();
    
    await docRef.set(transaction.toMap());
  }

  Future<void> updateTransaction(String userId, String transactionId, TransactionModel transaction) {
    return db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(transactionId)
        .update(transaction.toMap());
  }

  Future<void> deleteTransaction(String userId, String transactionId) {
    return db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(transactionId)
        .delete();
  }
  
  Future<void> createTransferRequest(String senderId, String recipientId, double amount) async {
  }

  // ===================================================================
  // == NOTIFICATION METHODS
  // ===================================================================

  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.id, doc.data()))
            .toList());
  }
  
  Future<void> addNotification(String userId, String title, String body) async {
    final notification = NotificationModel(
      id: '', 
      title: title,
      body: body,
      date: Timestamp.now(),
      read: false,
    );
    await db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add(notification.toMap());
  }

  Future<void> markNotificationAsRead(String userId, String notificationId) {
    return db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    final batch = db.batch();
    final querySnapshot = await db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();

    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }

    return batch.commit();
  }
  
  // ===================================================================
  // == CREDIT APPLICATION METHODS
  // ===================================================================

  Future<void> createCreditApplication(CreditApplicationModel application) {
    return db.collection('credit_applications').add(application.toMap());
  }

  Stream<List<CreditApplicationModel>> getCreditApplicationsStream(String userId) {
    return db
        .collection('credit_applications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CreditApplicationModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // ===================================================================
  // == DEPOSIT & WITHDRAWAL REQUESTS (ADMIN)
  // ===================================================================

  Stream<List<DepositRequestModel>> getPendingDepositRequestsStream() {
    return db
        .collection('deposit_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DepositRequestModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<WithdrawalRequestModel>> getPendingWithdrawalRequestsStream() {
    return db
        .collection('withdrawal_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WithdrawalRequestModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> approveDepositRequest(String requestId) async {
  }

  Future<void> approveWithdrawalRequest(String requestId) async {
  }

  Future<void> rejectDepositRequest(String requestId, String reason) async {
  }

  Future<void> rejectWithdrawalRequest(String requestId, String reason) async {
  }
  
  Future<void> createWithdrawalRequest({
    required String userId,
    required String beneficiaryName,
    required String iban,
    required double amount,
    required double fee,
    required double totalDebited,
  }) async {
    final user = await getUser(userId);

    if (user == null) {
      throw Exception("User not found when creating withdrawal request.");
    }

    final transactionId = db.collection('users').doc(userId).collection('transactions').doc().id;

    final request = WithdrawalRequestModel(
      id: '', 
      transactionId: transactionId,
      userId: userId,
      beneficiaryName: beneficiaryName,
      iban: iban,
      amount: amount,
      fee: fee,
      totalDebited: totalDebited,
      status: 'pending',
      createdAt: Timestamp.now(),
      userDisplayName: user.displayName,
      userEmail: user.email,
    );
    
    await db.collection('withdrawal_requests').add(request.toMap());
  }


  // ===================================================================
  // == COMMISSIONS & EARNINGS (CASHIER)
  // ===================================================================
  
  Stream<double> getCommissionBalanceStream(String cashierId) {
    return db.collection('users').doc(cashierId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return (snapshot.data()!['totalCommissions'] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    });
  }

  Stream<List<CommissionTransactionModel>> getCommissionHistoryStream(String cashierId) {
    return db
        .collection('users')
        .doc(cashierId)
        .collection('commissionTransactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommissionTransactionModel.fromMap(doc.id, doc.data()))
            .toList());
  }


  // ===================================================================
  // == REFERRAL METHODS
  // ===================================================================
  
  Future<String> getOrCreateReferralCode(String userId) async {
    final userDoc = await db.collection('users').doc(userId).get();
    if (userDoc.exists && userDoc.data()!.containsKey('referralCode')) {
      return userDoc.data()!['referralCode'];
    } else {
      final user = UserModel.fromMap(userDoc.data()!);
      final newCode = _generateReferralCode(user.displayName ?? 'USER');
      await db.collection('users').doc(userId).update({'referralCode': newCode});
      return newCode;
    }
  }

  Future<int> getReferralsCount(String userId) async {
    final querySnapshot = await db
        .collection('users')
        .where('referredBy', isEqualTo: userId)
        .get();
    return querySnapshot.docs.length;
  }

  // ===================================================================
  // == HELPER METHODS
  // ===================================================================

  String _generateReferralCode(String name) {
    final base = name.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    final sanitizedBase = base.length > 8 ? base.substring(0, 8) : base;
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final shortTimestamp = timestamp.substring(timestamp.length - 4);
    return '$sanitizedBase$shortTimestamp';
  }
}
