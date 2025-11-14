import 'package:afercon_pay/models/transaction_model.dart';
import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditTransactionScreen extends StatefulWidget {
  final TransactionModel transaction;

  const EditTransactionScreen({super.key, required this.transaction});

  @override
  EditTransactionScreenState createState() => EditTransactionScreenState();
}

class EditTransactionScreenState extends State<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late String _transactionType;
  late DateTime _selectedDate;

  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.transaction.description);
    _amountController =
        TextEditingController(text: widget.transaction.amount.toString());
    _transactionType = widget.transaction.type;
    _selectedDate = widget.transaction.date;
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

  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Nenhum utilizador logado.')),
      );
      return;
    }

    final updatedTransaction = TransactionModel(
      id: widget.transaction.id,
      userId: widget.transaction.userId,
      description: _descriptionController.text,
      amount: double.parse(_amountController.text),
      date: _selectedDate,
      type: _transactionType,
    );

    try {
      await _firestoreService.updateTransaction(
          _currentUser!.uid, widget.transaction.id, updatedTransaction);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteTransaction() async {
    if (_currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Nenhum utilizador logado.')),
      );
      return;
    }

    try {
      await _firestoreService.deleteTransaction(
          _currentUser!.uid, widget.transaction.id);
      if (!mounted) return;
      Navigator.of(context).pop(); // Close the confirmation dialog
      Navigator.of(context).pop(); // Close the edit screen
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close the confirmation dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao apagar: ${e.toString()}')),
      );
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar'),
          content:
              const Text('Tem a certeza de que deseja apagar esta transação?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: _deleteTransaction,
              child: const Text('Apagar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Transação'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isLoading ? null : _showDeleteConfirmationDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TextFormField(
                        controller: _descriptionController,
                        decoration:
                            const InputDecoration(labelText: 'Descrição'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira uma descrição.';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(labelText: 'Valor'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira um valor.';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Por favor, insira um número válido.';
                          }
                          return null;
                        },
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: _transactionType,
                        items: ['expense', 'revenue'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child:
                                Text(value == 'expense' ? 'Despesa' : 'Receita'),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() {
                              _transactionType = newValue;
                            });
                          }
                        },
                        decoration: const InputDecoration(
                            labelText: 'Tipo de Transação'),
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                                'Data: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
                          ),
                          TextButton(
                            onPressed: () => _selectDate(context),
                            child: const Text('Selecionar Data'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32.0),
                      Center(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          child: const Text('Salvar Alterações'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
