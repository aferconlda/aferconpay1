import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: Text('Meus Pedidos de Levantamento'),
      ),
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: const Center(
          child: Text('Nenhum pedido de levantamento encontrado.'),
        ),
      ),
    );
  }
}
