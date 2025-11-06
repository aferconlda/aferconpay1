import 'dart:async';
import 'package:afercon_pay/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PostLoginSplashScreen extends StatefulWidget {
  const PostLoginSplashScreen({super.key});

  @override
  State<PostLoginSplashScreen> createState() => _PostLoginSplashScreenState();
}

class _PostLoginSplashScreenState extends State<PostLoginSplashScreen> {
  late Timer _timer;
  int _countdown = 5;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        _navigateToHome();
      }
    });
  }

  void _navigateToHome() {
    _timer.cancel();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            Icon(
              Icons.wallet_rounded,
              size: 80.r,
              color: theme.colorScheme.primary,
            ),
            SizedBox(height: 20.h),
            Text(
              'Afercon Pay',
              style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40.h),
            Text(
              'Anúncio Especial!',
              style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
            ),
            SizedBox(height: 12.h),
            const Text(
              'Pague as suas contas de luz e água diretamente na app e ganhe 1% de cashback. Aproveite já!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const Spacer(),
            Text(
              'A aplicação iniciará em $_countdown s',
              style: theme.textTheme.bodySmall,
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: _navigateToHome,
                child: const Text('Saltar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
