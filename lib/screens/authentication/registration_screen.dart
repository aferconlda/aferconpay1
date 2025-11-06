
import 'package:afercon_pay/screens/authentication/verify_email_screen.dart';
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class RegistrationScreen extends StatefulWidget {
  final String? referrerCode;

  const RegistrationScreen({super.key, this.referrerCode});

  @override
  RegistrationScreenState createState() => RegistrationScreenState();
}

class RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _invitationCodeController = TextEditingController();

  final AuthService _authService = AuthService();
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  bool _isLoading = false;
  String? _errorMessage; 
  String? _validationMessageFromLink;

  @override
  void initState() {
    super.initState();
    if (widget.referrerCode != null) {
      _validateReferrerFromLink(widget.referrerCode!);
    }
  }

  Future<void> _validateReferrerFromLink(String referralCode) async {
    // Lógica existente inalterada
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _invitationCodeController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final UserCredential userCredential = await _authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        displayName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );
      final user = userCredential.user;

      if (user != null) {
        final manualCode = _invitationCodeController.text.trim();
        if (manualCode.isNotEmpty) {
          final callable = _functions.httpsCallable('validateReferrer');
          final result = await callable.call({'referralCode': manualCode});
          if (result.data['isValid'] != true) {
             throw Exception('O código de convite inserido é inválido.');
          }
        }

        FirebaseAnalytics.instance.logSignUp(signUpMethod: 'email_password');

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const VerifyEmailScreen()),
            (Route<dynamic> route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Este email já está a ser utilizado por outra conta.';
          break;
        case 'weak-password':
          message = 'A sua senha é muito fraca. Tente uma mais forte.';
          break;
        default:
          message = "Erro ao registar: ${e.message}";
      }
      if (mounted) {
        setState(() => _errorMessage = message);
      }
    } catch (e) {
      if (mounted) {
         setState(() => _errorMessage = "Ocorreu um erro: ${e.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const CustomAppBar(title: Text('Crie a sua Conta')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Card(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Image.asset(
                      'assets/logo.png',
                      height: 100.h,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'Bem-vindo à Afercon Pay',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Preencha os seus dados para começar.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),

                    if (_validationMessageFromLink != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 24.0),
                        child: Text(
                          _validationMessageFromLink!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _validationMessageFromLink!.contains('inválido')
                                ? Colors.red
                                : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    SizedBox(height: 32.h),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                                labelText: 'Nome Completo', prefixIcon: Icon(Icons.person_outline)),
                            keyboardType: TextInputType.name,
                            validator: (value) =>
                                value == null || value.isEmpty ? 'Por favor, insira o seu nome' : null,
                          ),
                          SizedBox(height: 16.h),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                                labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) =>
                                value == null || !value.contains('@') ? 'Por favor, insira um email válido' : null,
                          ),
                          SizedBox(height: 16.h),
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(labelText: 'Nº de Telemóvel', prefixIcon: Icon(Icons.phone_outlined), hintText: '912345678'),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              final phoneRegExp = RegExp(r'^9\d{8}$');
                              if (!phoneRegExp.hasMatch(value ?? '')) {
                                return 'Insira um nº de telemóvel angolano válido.';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16.h),
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                                labelText: 'Senha', prefixIcon: Icon(Icons.lock_outline)),
                            obscureText: true,
                            validator: (value) =>
                                value == null || value.length < 6 ? 'A senha deve ter no mínimo 6 caracteres' : null,
                          ),
                          SizedBox(height: 16.h),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: const InputDecoration(
                                labelText: 'Confirmar Senha', prefixIcon: Icon(Icons.lock_outline)),
                            obscureText: true,
                            validator: (value) =>
                                value != _passwordController.text ? 'As senhas não correspondem' : null,
                          ),
                          SizedBox(height: 16.h),
                          TextFormField(
                            controller: _invitationCodeController,
                            decoration: const InputDecoration(
                                labelText: 'Código de Convite (Opcional)',
                                prefixIcon: Icon(Icons.card_giftcard_outlined)),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    if (_errorMessage != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Text(_errorMessage!, style: TextStyle(color: theme.colorScheme.error), textAlign: TextAlign.center),
                      ),
                    SizedBox(height: 16.h),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _registerUser,
                            child: const Text('CRIAR CONTA'),
                          ),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Já tem uma conta?"),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Faça login'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
