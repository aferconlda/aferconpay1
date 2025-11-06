
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/services/pin_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _enteredPin = '';
  bool _isVerifying = false;
  String? _errorMessage;
  final PinService _pinService = PinService();
  final AuthService _authService = AuthService();

  void _onNumberPressed(String number) {
    if (_isVerifying || _enteredPin.length >= 6) return;
    setState(() {
      _errorMessage = null; // Limpa o erro ao digitar
      _enteredPin += number;
    });

    if (_enteredPin.length == 6) {
      _verifyPin();
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  Future<void> _verifyPin() async {
    setState(() => _isVerifying = true);
    final storedPin = await _pinService.getPin();

    // Adiciona um pequeno atraso para o utilizador perceber a verificação
    await Future.delayed(const Duration(milliseconds: 200));

    if (storedPin == _enteredPin) {
      widget.onUnlocked();
    } else {
      HapticFeedback.heavyImpact(); // Vibra em caso de erro
      setState(() {
        _errorMessage = 'PIN Incorreto';
        _enteredPin = '';
        _isVerifying = false;
      });
    }
  }

  Future<void> _logout() async {
    // Implementar a lógica de logout, talvez mostrando um diálogo de confirmação
    await _authService.signOut();
    // A navegação após o logout será tratada pelo widget wrapper principal
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40.w),
                    child: Column(
                      children: [
                        const Spacer(),
                        Icon(Icons.lock_outline, size: 40.sp, color: theme.colorScheme.primary),
                        SizedBox(height: 16.h),
                        Text('Aplicação Bloqueada', style: theme.textTheme.headlineSmall),
                        SizedBox(height: 8.h),
                        Text('Insira o seu PIN para continuar', style: theme.textTheme.bodyLarge),
                        SizedBox(height: 40.h),
                        _PinIndicator(enteredPin: _enteredPin),
                        if (_errorMessage != null)
                          Padding(
                            padding: EdgeInsets.only(top: 16.h),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold),
                            ),
                          ),
                        const Spacer(),
                        _NumericKeypad(
                          onNumberPressed: _onNumberPressed,
                          onDeletePressed: _onDeletePressed,
                        ),
                        SizedBox(height: 24.h),
                        TextButton(
                          onPressed: _logout,
                          child: const Text('Esqueceu o PIN? Sair da conta'),
                        ),
                        SizedBox(height: 24.h),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PinIndicator extends StatelessWidget {
  final String enteredPin;
  const _PinIndicator({required this.enteredPin});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 10.w),
          width: 18.w,
          height: 18.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < enteredPin.length
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
          ),
        );
      }),
    );
  }
}

class _NumericKeypad extends StatelessWidget {
  final Function(String) onNumberPressed;
  final VoidCallback onDeletePressed;

  const _NumericKeypad({
    required this.onNumberPressed,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['1', '2', '3'].map((e) => _KeypadButton(e, onPressed: () => onNumberPressed(e))).toList(),
        ),
        SizedBox(height: 20.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['4', '5', '6'].map((e) => _KeypadButton(e, onPressed: () => onNumberPressed(e))).toList(),
        ),
        SizedBox(height: 20.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['7', '8', '9'].map((e) => _KeypadButton(e, onPressed: () => onNumberPressed(e))).toList(),
        ),
        SizedBox(height: 20.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 72, height: 72), // Espaçador para alinhar
            _KeypadButton('0', onPressed: () => onNumberPressed('0')),
            _KeypadButton(
              '', // Vazio para o ícone
              onPressed: onDeletePressed,
              child: const Icon(Icons.backspace_outlined),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Widget? child;

  const _KeypadButton(this.text, {required this.onPressed, this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72, 
      height: 72,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: Colors.grey.shade100,
        ),
        child: child ?? Text(text, style: TextStyle(fontSize: 28.sp, color: Colors.black87)),
      ),
    );
  }
}
