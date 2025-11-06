import 'dart:async';
import 'package:afercon_pay/screens/security/lock_screen.dart';
import 'package:afercon_pay/screens/security/pin_setup_screen.dart';
import 'package:afercon_pay/services/pin_service.dart';
import 'package:flutter/material.dart';

const int inactivityTimeoutInMinutes = 2; // Alterado de 5 para 2 minutos

class InactivityDetector extends StatefulWidget {
  final Widget child;

  const InactivityDetector({super.key, required this.child});

  @override
  State<InactivityDetector> createState() => _InactivityDetectorState();
}

class _InactivityDetectorState extends State<InactivityDetector> {
  Timer? _timer;
  final PinService _pinService = PinService();

  bool _isLocked = false;
  bool? _isPinAlreadySet;

  @override
  void initState() {
    super.initState();
    _checkPinStatusAndInitialize();
  }

  void _checkPinStatusAndInitialize() async {
    final isSet = await _pinService.isPinSet();
    setState(() {
      _isPinAlreadySet = isSet;
    });
    if (isSet) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel(); // Cancela qualquer temporizador anterior
    _timer = Timer(const Duration(minutes: inactivityTimeoutInMinutes), _lockApp);
  }

  void _resetTimer() {
    if (_isPinAlreadySet == true && !_isLocked) {
      _startTimer();
    }
  }

  void _lockApp() {
    if (mounted && !_isLocked) {
      setState(() {
        _isLocked = true;
      });
      _timer?.cancel();
    }
  }

  void _unlockApp() {
    if (mounted) {
      setState(() {
        _isLocked = false;
      });
      _startTimer();
    }
  }

  void _onPinSet() {
    setState(() {
      _isPinAlreadySet = true;
    });
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isPinAlreadySet == null) {
      // Enquanto verifica se o PIN existe, mostra um ecrã de carregamento
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isPinAlreadySet!) {
      // Se o PIN não está definido, força a sua criação
      return PinSetupScreen(onPinSet: _onPinSet);
    }

    // Listener para reiniciar o temporizador em qualquer interação
    return GestureDetector(
      onTap: _resetTimer,
      onPanDown: (_) => _resetTimer(),
      onScaleStart: (_) => _resetTimer(),
      child: Stack(
        children: [
          widget.child,
          if (_isLocked)
            LockScreen(onUnlocked: _unlockApp),
        ],
      ),
    );
  }
}
