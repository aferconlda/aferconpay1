import 'package:afercon_pay/screens/settings/set_pin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:afercon_pay/services/pin_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Mostra um diálogo de confirmação de PIN seguro e reutilizável.
///
/// Retorna `true` se o PIN for verificado com sucesso, `false` caso contrário.
Future<bool> showPinConfirmationDialog(BuildContext context) async {
  final PinService pinService = PinService();

  final isPinSet = await pinService.isPinSet();
  
  if (!context.mounted) return false;

  // --- LÓGICA DE REDIRECIONAMENTO ---
  if (!isPinSet) {
    // Navega para o ecrã de configuração de PIN.
    final pinWasSet = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const SetPinScreen()),
    );

    // Se o PIN não foi configurado (ex: o utilizador voltou para trás),
    // mostra uma mensagem e cancela a operação.
    if (pinWasSet != true) {
       if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A configuração do PIN é necessária para continuar.'),
            backgroundColor: Colors.orange,
          ),
        );
       }
      return false;
    }

    // Se o PIN foi configurado, informa o utilizador para tentar a transação novamente.
    if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('PIN configurado. Por favor, inicie a transação novamente.'),
                backgroundColor: Colors.blue,
            ),
        );
    }
    return false; // Retorna false para que a transação não continue automaticamente.
  }

  // Se o PIN já está configurado, mostra o diálogo de confirmação normal.
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false, 
    builder: (BuildContext context) {
      return _PinConfirmationDialogContent(pinService: pinService);
    },
  );
  return result ?? false;
}


/// O conteúdo interno do diálogo.
class _PinConfirmationDialogContent extends StatefulWidget {
  final PinService pinService;

  const _PinConfirmationDialogContent({required this.pinService});

  @override
  _PinConfirmationDialogContentState createState() => _PinConfirmationDialogContentState();
}

class _PinConfirmationDialogContentState extends State<_PinConfirmationDialogContent> {
  String _enteredPin = "";
  String? _errorMessage;

  void _onNumberPressed(String number) {
    if (_enteredPin.length < 6) {
      setState(() {
        _enteredPin += number;
        _errorMessage = null; // Limpa o erro ao inserir novo dígito
      });

      if (_enteredPin.length == 6) {
        _verifyPin();
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

  Future<void> _verifyPin() async {
    final storedPin = await widget.pinService.getPin();

    if (!mounted) return;

    if (_enteredPin == storedPin) {
      Navigator.of(context).pop(true); // Sucesso!
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = "PIN Incorreto. Tente novamente.";
        _enteredPin = ""; // Limpa o PIN para nova tentativa
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: const Text("Confirmar Transação", textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Introduza o seu PIN de segurança para continuar.", textAlign: TextAlign.center,),
          SizedBox(height: 24.h),
          _buildPinDots(theme),
          if (_errorMessage != null)
            Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 14.sp),
                textAlign: TextAlign.center,
              ),
            ),
          SizedBox(height: 24.h),
          _buildNumpad(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false), // Ação de cancelar
          child: const Text("CANCELAR"),
        ),
      ],
    );
  }

  // Representação visual dos dígitos do PIN
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

  // Teclado numérico personalizado
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
            SizedBox(width: 70.w, height: 70.h), // Espaço vazio para alinhar
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
