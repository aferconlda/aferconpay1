import 'package:afercon_pay/services/pin_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Enum para controlar o estado do ecrã
enum PinScreenState { create, confirm }

class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final PinService _pinService = PinService();
  PinScreenState _screenState = PinScreenState.create;
  
  String _enteredPin = "";
  String _tempPin = ""; // Para guardar o primeiro PIN inserido
  String? _errorMessage;

  String get _title {
    return _screenState == PinScreenState.create 
      ? "Crie o seu PIN de Segurança"
      : "Confirme o seu PIN";
  }

  String get _subtitle {
    return _screenState == PinScreenState.create
      ? "Este PIN será usado para autorizar todas as suas transações."
      : "Introduza novamente o PIN para confirmar.";
  }

  void _onNumberPressed(String number) {
    if (_enteredPin.length < 6) {
      setState(() {
        _enteredPin += number;
        _errorMessage = null;
      });

      if (_enteredPin.length == 6) {
        _processPin();
      }
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _processPin() {
    if (_screenState == PinScreenState.create) {
      // Primeira fase: guardar o PIN temporariamente e passar para a confirmação
      setState(() {
        _tempPin = _enteredPin;
        _enteredPin = "";
        _screenState = PinScreenState.confirm;
      });
    } else {
      // Segunda fase: comparar o PIN de confirmação com o PIN temporário
      if (_enteredPin == _tempPin) {
        _savePinAndExit();
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _errorMessage = "Os PINs não correspondem. Tente novamente desde o início.";
          _enteredPin = "";
          _tempPin = "";
          _screenState = PinScreenState.create; // Reinicia o processo
        });
      }
    }
  }

  Future<void> _savePinAndExit() async {
    try {
      await _pinService.savePin(_enteredPin);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN de segurança definido com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      // Retorna `true` para indicar que o PIN foi configurado com sucesso
      Navigator.of(context).pop(true); 
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Erro ao guardar o PIN. Tente novamente.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar PIN de Segurança'),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Text(_title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                SizedBox(height: 12.h),
                Text(_subtitle, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
                SizedBox(height: 48.h),
                _buildPinDots(theme),
                if (_errorMessage != null)
                  Padding(
                    padding: EdgeInsets.only(top: 24.h),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: theme.colorScheme.error, fontSize: 14.sp),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
            _buildNumpad(),
          ],
        ),
      ),
    );
  }

  Widget _buildPinDots(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 8.w),
          width: 18.w,
          height: 18.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < _enteredPin.length ? theme.primaryColor : Colors.transparent,
            border: Border.all(color: theme.disabledColor, width: 1.5),
          ),
        );
      }),
    );
  }

  Widget _buildNumpad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ["1", "2", "3"].map((e) => _buildNumberButton(e)).toList(),
        ),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ["4", "5", "6"].map((e) => _buildNumberButton(e)).toList(),
        ),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ["7", "8", "9"].map((e) => _buildNumberButton(e)).toList(),
        ),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(width: 70.w, height: 70.h),
            _buildNumberButton("0"),
            _buildDeleteButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberButton(String number) {
    return SizedBox(
      width: 70.w,
      height: 70.h,
      child: TextButton(
        style: TextButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: Theme.of(context).primaryColor.withAlpha(13),
        ),
        onPressed: () => _onNumberPressed(number),
        child: Text(number, style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      width: 70.w,
      height: 70.h,
      child: IconButton(
        onPressed: _onDeletePressed,
        icon: const Icon(Icons.backspace_outlined),
        iconSize: 28.sp,
      ),
    );
  }
}
