import 'package:afercon_pay/models/transaction_model.dart';
import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/screens/transactions/transaction_detail_screen.dart';
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authUser = _authService.getCurrentUser();
    if (mounted) {
      if (authUser != null) {
        final userModel = await _firestoreService.getUser(authUser.uid);
        setState(() {
          _currentUser = userModel;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz');

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? const Center(child: Text('Utilizador não encontrado.'))
              : Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: StreamBuilder<List<TransactionModel>>(
                    stream: _firestoreService
                        .getTransactionsStream(_currentUser!.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                            child: Text('Erro: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            'Nenhuma transação encontrada.',
                            style: TextStyle(
                                fontSize: 16.sp, color: Colors.grey),
                          ),
                        );
                      }

                      final transactions = snapshot.data!;

                      return ListView.builder(
                        padding: EdgeInsets.symmetric(
                            vertical: 8.h, horizontal: 16.w),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          final isRevenue = transaction.amount >= 0;
                          final formattedDate = DateFormat(
                                  'dd MMM, yyyy HH:mm', 'pt_AO')
                              .format(transaction.date);

                          return Card(
                            elevation: 2,
                            margin: EdgeInsets.symmetric(vertical: 6.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 8.h, horizontal: 16.w),
                              leading: CircleAvatar(
                                radius: 20.r,
                                backgroundColor: isRevenue
                                    ? const Color.fromARGB(38, 76, 175, 80)
                                    : const Color.fromARGB(
                                        38, 244, 67, 54),
                                child: Icon(
                                  isRevenue
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: isRevenue
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                  size: 20.r,
                                ),
                              ),
                              title: Text(
                                transaction.description,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.sp),
                              ),
                              subtitle: Padding(
                                padding: EdgeInsets.only(top: 4.h),
                                child: Text(
                                  formattedDate,
                                  style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12.sp),
                                ),
                              ),
                              trailing: Text(
                                isRevenue ? '+ ${currencyFormat.format(transaction.amount)}' : currencyFormat.format(transaction.amount),
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isRevenue
                                      ? Colors.green[800]
                                      : Colors.red[800],
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        TransactionDetailScreen(
                                            transaction: transaction),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
