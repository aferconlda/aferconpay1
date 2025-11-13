
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ForgotPasswordScreenState createState() => ForgotPasswordScreenState();
}

class ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordResetEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.sendPasswordResetEmail(_emailController.text.trim());

      if (mounted) {
        _showSuccessDialog();
      }

    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
         // To prevent user enumeration, we treat 'user-not-found' as a success.
         // This is a security best practice.
        if (mounted) {
          _showSuccessDialog();
        }
      } else {
         if (mounted) {
          setState(() {
            _errorMessage = 'Ocorreu um erro. Por favor, tente novamente.';
          });
        }
      }
    } catch (_) {
       if (mounted) {
          setState(() {
            _errorMessage = 'Ocorreu um erro inesperado. Tente novamente.';
          });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Verifique o seu Email'),
          content: const Text('Se existir uma conta associada a este email, enviámos um link para redefinir a sua senha. Por favor, verifique a sua caixa de entrada e a pasta de spam.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Go back to the login screen
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(title: Text('Recuperar Senha')),
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
                      'Recuperar Senha',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Insira o seu email e, se estiver registado, enviaremos um link para redefinir a sua senha.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    Form(
                        key: _formKey,
                        child: TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email de Registo',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) =>
                              value == null || !value.contains('@') ? 'Por favor, insira um email válido' : null,
                        ),
                    ),
                     if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: theme.colorScheme.error, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 32),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _sendPasswordResetEmail,
                            child: const Text('ENVIAR LINK DE RECUPERAÇÃO'),
                          ),
                    const SizedBox(height: 16),
                     TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Voltar ao Login'),
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
