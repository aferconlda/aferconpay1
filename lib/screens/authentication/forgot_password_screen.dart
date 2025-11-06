
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordResetEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    bool emailSuccessfullySent = false;

    try {
      await _authService.sendPasswordResetEmail(_emailController.text);
      emailSuccessfullySent = true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('O formato do email é inválido.')));
      } else {
        emailSuccessfullySent = true; 
      }
    } catch (e) {
      emailSuccessfullySent = true; 
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        if (emailSuccessfullySent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Se existir uma conta com este email, um link de recuperação foi enviado.')),
          );
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(title: Text('Recuperar Senha')),
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
                      'Recuperar Senha',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Insira o seu email e, se estiver registado, enviaremos um link para redefinir a sua senha.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    SizedBox(height: 32.h),
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
                    SizedBox(height: 32.h),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _sendPasswordResetEmail,
                            child: const Text('ENVIAR LINK'),
                          ),
                    SizedBox(height: 16.h),
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
