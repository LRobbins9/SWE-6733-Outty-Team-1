import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outty/screens/auth_screen.dart';

void main() {
  testWidgets('Auth screen renders without Firebase initialization', (tester) async {
    // Simple smoke test of AuthScreen without Firebase network calls.
    // Comprehensive feature tests in test/features/ cover full auth flow.
    await tester.pumpWidget(
      const MaterialApp(home: AuthScreen()),
    );
    
    expect(find.text('OUTTY'), findsOneWidget);
    expect(find.text('Find Your Adventure Partner'), findsOneWidget);
    expect(find.text('Sign in to Outty'), findsOneWidget);
  });
}
