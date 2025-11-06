import 'package:afercon_pay/services/pin_service.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pinput/pinput.dart';

// Enum para controlar o passo atual do fluxo
enum _PinStep { verifyOld, enterNew, confirmNew }

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final _pinService = PinService();
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  _PinStep _currentStep = _PinStep.verifyOld;
  String _newPin = '';
  String _feedbackMessage = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _updateFeedbackMessage();
  }

  // Atualiza a mensagem de instrução com base no passo atual
  void _updateFeedbackMessage() {
    setState(() {
      switch (_currentStep) {
        case _PinStep.verifyOld:
          _feedbackMessage = 'Introduza o seu PIN antigo para continuar';
          break;
        case _PinStep.enterNew:
          _feedbackMessage = 'Defina o seu novo PIN de 6 dígitos';
          break;
        case _PinStep.confirmNew:
          _feedbackMessage = 'Confirme o seu novo PIN';
          break;
      }
    });
  }

  // Função principal que gere a submissão do PIN
  Future<void> _submitPin(String pin) async {
    if (pin.length != 6) return;
    setState(() => _isLoading = true);

    try {
      switch (_currentStep) {
        case _PinStep.verifyOld:
          await _verifyOldPin(pin);
          break;
        case _PinStep.enterNew:
          _handleNewPin(pin);
          break;
        case _PinStep.confirmNew:
          await _confirmNewPin(pin);
          break;
      }
    } catch (e) {
      _showErrorSnackbar(e.toString());
    } finally {
      _pinController.clear();
      if(mounted) setState(() => _isLoading = false);
    }
  }

  // Verifica se o PIN antigo está correto
  Future<void> _verifyOldPin(String pin) async {
    final storedPin = await _pinService.getPin();
    if (storedPin == pin) {
      setState(() {
        _currentStep = _PinStep.enterNew;
        _updateFeedbackMessage();
      });
    } else {
      _showErrorSnackbar('PIN Antigo incorreto. Tente novamente.');
    }
  }

  // Guarda o novo PIN temporariamente
  void _handleNewPin(String pin) {
    setState(() {
      _newPin = pin;
      _currentStep = _PinStep.confirmNew;
      _updateFeedbackMessage();
    });
  }

  // Confirma e guarda o novo PIN permanentemente
  Future<void> _confirmNewPin(String pin) async {
    if (pin == _newPin) {
      await _pinService.savePin(_newPin);
      _showSuccessDialog();
    } else {
      // Se a confirmação falhar, volta ao início do processo
      _showErrorSnackbar('Os PINs não coincidem. Comece de novo.');
      setState(() {
        _currentStep = _PinStep.verifyOld;
        _updateFeedbackMessage();
      });
    }
  }
  
  void _showErrorSnackbar(String message) {
     if(mounted){
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
      );
     }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Sucesso!'),
        content: const Text('O seu PIN de transação foi alterado com sucesso.'),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(); // Fecha o dialogo
              Navigator.of(context).pop(); // Volta para a tela de perfil
            },
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(fontSize: 22, color: Colors.black),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.transparent),
      ),
    );

    return Scaffold(
      appBar: const CustomAppBar(title: Text('Alterar PIN de Transação')),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _feedbackMessage,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.h),
                Pinput(
                  length: 6,
                  controller: _pinController,
                  obscureText: true,
                  autofocus: true,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      border: Border.all(color: Theme.of(context).primaryColor),
                    ),
                  ),
                  onCompleted: (pin) => _submitPin(pin),
                  enabled: !_isLoading,
                ),
                SizedBox(height: 32.h),
                if (_isLoading) const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
