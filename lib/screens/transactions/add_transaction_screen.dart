import 'package:afercon_pay/models/transaction_model.dart';
import 'package:afercon_pay/models/user_model.dart';
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  AddTransactionScreenState createState() => AddTransactionScreenState();
}

class AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String _transactionType = 'expense';
  DateTime _selectedDate = DateTime.now();

  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  double _userBalance = 0.0;
  bool _isBalanceLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() {
      _isBalanceLoading = true;
    });
    try {
      final authUser = _authService.getCurrentUser();
      if (mounted) {
        if (authUser != null) {
          final userModel = await _firestoreService.getUser(authUser.uid);
          setState(() {
            _currentUser = userModel;
            _userBalance = _currentUser?.balance['AOA'] ?? 0.0;
          });
        } else {
          setState(() {
            _currentUser = null;
            _userBalance = 0.0;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados do utilizador: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBalanceLoading = false;
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

    final newTransaction = TransactionModel(
      id: '',
      description: _descriptionController.text,
      amount: double.parse(_amountController.text.replaceAll(',', '.')),
      date: _selectedDate,
      type: _transactionType,
    );

    try {
      await _firestoreService.addTransaction(_currentUser!.uid, newTransaction);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transação adicionada com sucesso!')),
      );
      Navigator.of(context).pop();

    } on Exception catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'pt_AO', symbol: 'Kz');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Transação'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                DropdownButtonFormField<String>(
                  initialValue: _transactionType,
                  items: ['expense', 'revenue'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value == 'expense' ? 'Pagamento (Despesa)' : 'Entrada (Receita)'),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        _transactionType = newValue;
                        _formKey.currentState?.validate();
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Tipo de Transação'),
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira uma descrição.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                if (_transactionType == 'expense')
                  _isBalanceLoading
                      ? const Padding(padding: EdgeInsets.only(bottom: 8.0), child: LinearProgressIndicator())
                      : Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: Text(
                            'Saldo disponível: ${currencyFormat.format(_userBalance)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'Valor', suffixText: 'Kz'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira um valor.';
                    }
                    final amount = double.tryParse(value.replaceAll(',', '.'));
                    if (amount == null || amount <= 0) {
                      return 'Por favor, insira um número válido.';
                    }
                    if (_transactionType == 'expense' && amount > _userBalance) {
                      return 'Saldo insuficiente.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
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
                SizedBox(height: 32.h),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Adicionar Transação'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
