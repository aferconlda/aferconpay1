import 'package:afercon_pay/screens/authentication/forgot_password_screen.dart';
import 'package:afercon_pay/screens/authentication/registration_screen.dart';
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum LoginType { email, phone }

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  LoginType _loginType = LoginType.email;
  bool _isAwaitingSms = false;
  String? _verificationId;

  // State for password visibility
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }

  Future<void> _processLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_loginType == LoginType.email) {
        await _loginWithEmail();
      } else if (!_isAwaitingSms) {
        await _requestSmsCode();
      } else {
        await _signInWithSmsCode();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loginWithEmail() async {
    try {
      final userCredential = await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      
      final user = userCredential.user;
      if (user != null) {
        if (!user.emailVerified) {
          // If email is not verified, send a new verification email and show a message
          await user.sendEmailVerification();
          await _authService.signOut(); // Sign out the user

          if (mounted) {
            setState(() {
              _errorMessage = 'A sua conta não foi verificada. Enviámos um novo link de verificação para o seu email. Por favor, verifique a sua caixa de entrada (e a pasta de spam).';
            });
          }
        } 
        // If email is verified, the AuthGate will handle navigation
      }

    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Email ou senha inválidos. Por favor, tente novamente.';
          break;
        case 'invalid-email':
          message = 'O formato do email é inválido.';
          break;
        case 'user-disabled':
          message = 'Esta conta foi desativada.';
          break;
        default:
          message = 'Ocorreu um erro. Por favor, tente mais tarde.';
      }
      if (mounted) {
        setState(() {
          _errorMessage = message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ocorreu um erro inesperado. Tente novamente.';
        });
      }
    }
  }

  // CORRIGIDO: Agora usa o número de telemóvel do campo de texto
  Future<void> _requestSmsCode() async {
    final phoneNumber = '+244${_phoneController.text.trim()}';
    await _authService.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        if (mounted) {
          setState(() {
            _isLoading = true;
          });
          await _signInWithPhone(credential);
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        String message;
        switch (e.code) {
          case 'invalid-phone-number':
            message = 'O número de telemóvel fornecido não é válido.';
            break;
          case 'too-many-requests':
            message = 'Muitas tentativas. Por favor, tente mais tarde.';
            break;
          default:
            message = 'Falha na verificação. Tente novamente.';
        }
        if (mounted) {
          setState(() {
            _errorMessage = message;
            _isLoading = false;
          });
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
            _isAwaitingSms = true;
            _isLoading = false;
          });
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<void> _signInWithSmsCode() async {
    if (_verificationId == null) return;

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: _smsCodeController.text.trim(),
    );
    await _signInWithPhone(credential);
  }

  Future<void> _signInWithPhone(PhoneAuthCredential credential) async {
    try {
      await _authService.signInWithPhoneCredential(credential);
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'invalid-verification-code') {
        message = 'O código inserido está incorreto. Tente novamente.';
      } else {
        message = 'Falha no login. Por favor, tente novamente.';
      }
      if (mounted) {
        setState(() {
          _errorMessage = message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ocorreu um erro inesperado.';
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
      appBar: const CustomAppBar(title: Text('Faça Login')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Bem-vindo de volta!',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Insira as suas credenciais para continuar.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 32),
                      _buildLoginSelector(),
                      const SizedBox(height: 24),
                      if (_loginType == LoginType.email) ..._buildEmailFields(),
                      if (_loginType == LoginType.phone) ..._buildPhoneFields(),
                      const SizedBox(height: 16),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(_errorMessage!, style: TextStyle(color: theme.colorScheme.error), textAlign: TextAlign.center),
                        ),
                      const SizedBox(height: 16),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _buildLoginButton(),
                      const SizedBox(height: 24),
                      _buildRegistrationLink(),
                      const SizedBox(height: 32),
                      _buildSecurityNotice(theme),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),
                      _buildSupportInfo(theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityNotice(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.security, size: 20, color: theme.colorScheme.onSurface.withAlpha((255 * 0.6).round())),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Nunca partilhe a sua senha. A equipa Afercon Pay nunca solicita esta informação.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportInfo(ThemeData theme) {
    final bodySmall = theme.textTheme.bodySmall?.copyWith(fontSize: 13);
    return Column(
      children: [
        Text(
          'Apoio ao Cliente',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.phone_outlined, size: 16),
            const SizedBox(width: 8),
            Text('+244 945 100 502', style: bodySmall),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.message_outlined, size: 16), // Ícone para WhatsApp
            const SizedBox(width: 8),
            Text('+244 945 100 502 (WhatsApp)', style: bodySmall),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.email_outlined, size: 16),
            const SizedBox(width: 8),
            Text('apoioaocliente@aferconpay.net', style: bodySmall),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginSelector() {
    return Center(
      child: ToggleButtons(
        isSelected: [_loginType == LoginType.email, _loginType == LoginType.phone],
        onPressed: (index) {
          setState(() {
            _loginType = index == 0 ? LoginType.email : LoginType.phone;
            _errorMessage = null;
            _isAwaitingSms = false;
            _formKey.currentState?.reset();
          });
        },
        borderRadius: BorderRadius.circular(8),
        constraints: const BoxConstraints(minHeight: 40, minWidth: 100),
        children: const [
          Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text('Email')),
          Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text('Telemóvel')),
        ],
      ),
    );
  }

  List<Widget> _buildEmailFields() {
    return [
      TextFormField(
        controller: _emailController,
        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
        keyboardType: TextInputType.emailAddress,
        validator: (value) => (value?.isEmpty ?? true) || !value!.contains('@') ? 'Insira um email válido' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _passwordController,
        obscureText: !_isPasswordVisible,
        decoration: InputDecoration(
          labelText: 'Senha',
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
        ),
        validator: (value) => (value?.isEmpty ?? true) ? 'Insira a sua senha' : null,
      ),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (c) => const ForgotPasswordScreen())),
          child: const Text('Esqueceu-se da senha?'),
        ),
      ),
    ];
  }

  List<Widget> _buildPhoneFields() {
    return [
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _isAwaitingSms
            ? TextFormField(
                key: const ValueKey('sms_code'),
                controller: _smsCodeController,
                decoration: const InputDecoration(labelText: 'Código de Verificação SMS', prefixIcon: Icon(Icons.sms_outlined)),
                keyboardType: TextInputType.number,
                validator: (value) => (value?.length ?? 0) != 6 ? 'O código deve ter 6 dígitos' : null,
              )
            : TextFormField(
                key: const ValueKey('phone_number'),
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
      ),
    ];
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
      onPressed: _isLoading ? null : _processLogin,
      child: Text(
        _loginType == LoginType.email
            ? 'ENTRAR'
            : (_isAwaitingSms ? 'VERIFICAR E ENTRAR' : 'ENVIAR CÓDIGO'),
      ),
    );
  }

  Widget _buildRegistrationLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Não tem uma conta?'),
        TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (c) => const RegistrationScreen())),
          child: const Text('Registe-se'),
        ),
      ],
    );
  }
}
