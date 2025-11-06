import 'package:afercon_pay/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class TransactionListItem extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionListItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpense = transaction.type == 'expense';
    final currencyFormat = NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    final Color amountColor = isExpense ? Colors.redAccent : Colors.green;
    final IconData iconData = isExpense ? Icons.arrow_upward : Icons.arrow_downward;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      child: ListTile(
        leading: Icon(iconData, color: amountColor, size: 28.sp),
        title: Text(
          transaction.description,
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          dateFormat.format(transaction.date),
          style: theme.textTheme.bodySmall,
        ),
        trailing: Text(
          '${isExpense ? '-' : '+'} ${currencyFormat.format(transaction.amount)}',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: amountColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
