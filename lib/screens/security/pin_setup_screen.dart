
import 'package:afercon_pay/services/pin_service.dart';
import 'package:afercon_pay/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PinSetupScreen extends StatefulWidget {
  final VoidCallback onPinSet;

  const PinSetupScreen({super.key, required this.onPinSet});

  @override
  PinSetupScreenState createState() => PinSetupScreenState();
}

class PinSetupScreenState extends State<PinSetupScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _pinService = PinService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _savePin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      await _pinService.savePin(_pinController.text);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN de segurança definido com sucesso!')),
        );
        widget.onPinSet(); // Notifica o widget pai que o PIN foi definido
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao guardar o PIN: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: Text('Configurar PIN de Segurança')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Crie um PIN de 6 dígitos para proteger a sua conta.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 32.h),
              TextFormField(
                controller: _pinController,
                decoration: const InputDecoration(
                  labelText: 'PIN de 6 dígitos',
                  prefixIcon: Icon(Icons.pin),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                validator: (value) {
                  if (value == null || value.length != 6) {
                    return 'O PIN deve ter exatamente 6 dígitos.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _confirmPinController,
                decoration: const InputDecoration(
                  labelText: 'Confirmar PIN',
                  prefixIcon: Icon(Icons.pin),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                validator: (value) {
                  if (value != _pinController.text) {
                    return 'Os PINs não correspondem.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 48.h),
              ElevatedButton(
                onPressed: _isLoading ? null : _savePin,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('GUARDAR PIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
