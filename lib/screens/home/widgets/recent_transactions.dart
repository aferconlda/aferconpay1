import 'package:afercon_pay/models/transaction_model.dart';
import 'package:afercon_pay/screens/transactions/transaction_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class RecentTransactions extends StatelessWidget {
  final List<TransactionModel> transactions;
  final NumberFormat format;
  final bool isLoading;

  const RecentTransactions({
    super.key,
    required this.transactions,
    required this.format,
    this.isLoading = false, 
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recentTransactions = transactions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Text('Transações Recentes', style: theme.textTheme.titleLarge),
        ),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (recentTransactions.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Text('Nenhuma transação ainda.', style: theme.textTheme.bodyMedium),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentTransactions.length,
            itemBuilder: (context, index) {
              final transaction = recentTransactions[index];
              final isRevenue = transaction.amount >= 0;
              return Card(
                margin: EdgeInsets.symmetric(vertical: 6.h),
                child: ListTile(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TransactionDetailScreen(transaction: transaction),
                      ),
                    );
                  },
                  leading: Icon(
                    isRevenue ? Icons.arrow_circle_up_outlined : Icons.arrow_circle_down_outlined,
                    color: isRevenue ? theme.primaryColor : theme.colorScheme.error,
                    size: 32.sp,
                  ),
                  title: Text(transaction.description, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Text(DateFormat('dd MMM, yyyy', 'pt_AO').format(transaction.date), style: theme.textTheme.bodySmall),
                  trailing: Text(
                    isRevenue ? '+ ${format.format(transaction.amount)}' : format.format(transaction.amount),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isRevenue ? theme.primaryColor : theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
