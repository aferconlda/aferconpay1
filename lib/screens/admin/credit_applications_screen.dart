import 'package:afercon_pay/models/credit_application_model.dart';
import 'package:afercon_pay/screens/admin/credit_application_detail_screen.dart';
import 'package:afercon_pay/services/credit_service.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreditApplicationsScreen extends StatefulWidget {
  const CreditApplicationsScreen({super.key});

  @override
  State<CreditApplicationsScreen> createState() => _CreditApplicationsScreenState();
}

class _CreditApplicationsScreenState extends State<CreditApplicationsScreen> {
  final CreditService _creditService = CreditService();

  // REFACTOR: State variable for the Stream
  late Stream<QuerySnapshot> _applicationsStream;

  @override
  void initState() {
    super.initState();
    // REFACTOR: Initialize stream in initState
    _applicationsStream = _creditService.getPendingCreditApplications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: Text('Pedidos de Crédito Pendentes')),
      body: StreamBuilder<QuerySnapshot>(
        // REFACTOR: Use stream from state variable
        stream: _applicationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Não há pedidos de crédito pendentes.'),
            );
          }

          final applications = snapshot.data!.docs;
          final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'AOA');

          return ListView.builder(
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final doc = applications[index];
              final data = doc.data() as Map<String, dynamic>;

              // Usar o modelo para garantir a segurança dos tipos
              final application = CreditApplicationModel.fromMap(doc.id, data);

              final String creditTypeDisplay =
                  application.creditType == 'personal' ? 'Pessoal' : 'Empresarial';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(application.creditType == 'personal'
                        ? Icons.person_outline
                        : Icons.business_center_outlined),
                  ),
                  title: Text(
                    data['fullName'] ?? 'Nome não disponível', // O nome já está no pedido
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${currencyFormat.format(application.amount)} - $creditTypeDisplay',
                  ),
                  trailing: const Icon(Icons.keyboard_arrow_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CreditApplicationDetailScreen(
                          applicationId: application.id!,
                          applicationData: data, // Passar todos os dados
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
