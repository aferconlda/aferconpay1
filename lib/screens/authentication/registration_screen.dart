
import 'dart:async';
import 'package:afercon_pay/screens/authentication/verify_email_screen.dart';
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  final _nifController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _invitationCodeController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // Preenche o campo de convite se um código for passado via link
    if (widget.referrerCode != null) {
      _invitationCodeController.text = widget.referrerCode!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nifController.dispose();
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
      // REPARADO: A lógica de registo agora envia o código de convite diretamente.
      await _authService.signUpWithPhoneNumberCheck(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        displayName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        nif: _nifController.text.trim(),
        referralCode: _invitationCodeController.text.trim().isEmpty 
            ? null 
            : _invitationCodeController.text.trim(),
      );

      final user = _authService.authCurrentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }

      FirebaseAnalytics.instance.logSignUp(signUpMethod: 'email_password');

      if (mounted) {
        unawaited(Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const VerifyEmailScreen()),
          (Route<dynamic> route) => false,
        ));
      }
    } on FirebaseAuthException catch (e) {
        if (mounted) {
            String message;
            if (e.code == 'email-already-in-use') {
                message = 'Este endereço de e-mail já está a ser utilizado por outra conta.';
            } else if (e.code == 'weak-password') {
                message = 'A senha é demasiado fraca. Tente uma mais forte.';
            } else {
                message = 'Ocorreu um erro de autenticação. Por favor, tente novamente.';
            }
            setState(() {
                _errorMessage = message;
            });
        }
    } on FirebaseFunctionsException catch (e) {
        // Apanha erros da Cloud Function (ex: código de convite inválido)
        if (mounted) {
            setState(() {
                _errorMessage = e.message ?? "Ocorreu um erro ao validar os seus dados. Tente novamente.";
            });
        }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Ocorreu um erro inesperado. Por favor, tente novamente.";
        });
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
      backgroundColor: theme.colorScheme.surface,
      appBar: const CustomAppBar(title: Text('Crie a sua Conta')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Image.asset(
                      'assets/logo.png',
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Bem-vindo à Afercon Pay',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Preencha os seus dados para começar.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),

                    const SizedBox(height: 32),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                                labelText: 'Nome Completo',
                                prefixIcon: Icon(Icons.person_outline)),
                            keyboardType: TextInputType.name,
                            validator: (value) => value == null || value.isEmpty
                                ? 'Por favor, insira o seu nome'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined)),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) =>
                                value == null || !value.contains('@')
                                    ? 'Por favor, insira um email válido'
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                                labelText: 'Nº de Telemóvel',
                                prefixIcon: Icon(Icons.phone_outlined),
                                hintText: '912345678'),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              final phoneRegExp = RegExp(r'^9\d{8}$');
                              if (!phoneRegExp.hasMatch(value ?? '')) {
                                return 'Insira um nº de telemóvel angolano válido.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nifController,
                            decoration: const InputDecoration(
                                labelText: 'NIF (Número de Identificação Fiscal)',
                                prefixIcon: Icon(Icons.badge_outlined)),
                            keyboardType: TextInputType.text,
                            validator: (value) => value == null || value.isEmpty
                                ? 'Por favor, insira o seu NIF'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            validator: (value) =>
                                value == null || value.length < 6
                                    ? 'A senha deve ter no mínimo 6 caracteres'
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: !_isConfirmPasswordVisible,
                             decoration: InputDecoration(
                              labelText: 'Confirmar Senha',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_isConfirmPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off),
                                onPressed: () {
                                  setState(() {
                                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            validator: (value) => value != _passwordController.text
                                ? 'As senhas não correspondem'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _invitationCodeController,
                            decoration: const InputDecoration(
                                labelText: 'Código de Convite (Opcional)',
                                prefixIcon:
                                    Icon(Icons.card_giftcard_outlined)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(_errorMessage!,
                            style: TextStyle(color: theme.colorScheme.error),
                            textAlign: TextAlign.center),
                      ),
                    const SizedBox(height: 16),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _registerUser,
                            child: const Text('CRIAR CONTA'),
                          ),
                    const SizedBox(height: 16),
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
