// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:afercon_pay/main.dart';

void main() {
  testWidgets('App starts without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // This is a smoke test to verify the app can be rendered.
    await tester.pumpWidget(const AferconPayApp());

    // As the initial screen is LoginScreen, we can verify if a login-specific widget is present.
    expect(find.byType(ElevatedButton), findsWidgets);
    expect(find.text('ENTRAR'), findsOneWidget);
  });
}
