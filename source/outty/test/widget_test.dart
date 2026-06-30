// This is a basic widget test for the Outty app.
// It verifies that the SplashScreen renders without errors.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:outty/main.dart';
import 'package:outty/providers/auth_provider.dart';
import 'package:outty/providers/chat_provider.dart';
import 'package:outty/providers/match_provider.dart';
import 'package:outty/providers/navigation_notifier.dart';
import 'package:outty/screens/splash_screen.dart';

void main() {
  testWidgets('OuttyApp renders SplashScreen on launch', (tester) async {
    await tester.pumpWidget(const OuttyApp());
    // The splash screen shows the app name
    expect(find.text('Outty'), findsOneWidget);
  });

  testWidgets('SplashScreen shows branding elements', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => MatchProvider()),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
          ChangeNotifierProvider(create: (_) => NavigationNotifier()),
        ],
        child: const MaterialApp(
          home: SplashScreen(),
        ),
      ),
    );

    expect(find.text('Outty'), findsOneWidget);
    expect(find.text('Find your adventure partner'), findsOneWidget);
  });
}
