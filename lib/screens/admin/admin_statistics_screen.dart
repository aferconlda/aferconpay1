import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';

class AdminStatisticsScreen extends StatelessWidget {
  const AdminStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(title: Text('Estatísticas Gerais')),
      body: Center(
        child: Text('Ecrã de estatísticas em construção.'),
      ),
    );
  }
}
