import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/user_onboarding_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _buildTheme() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF4CAF50),
      onPrimary: Color(0xFF003910),
      secondary: Color(0xFF1E88E5),
      onSecondary: Color(0xFF001D36),
      tertiary: Color(0xFF78909C),
      onTertiary: Color(0xFF0D1B21),
      error: Color(0xFFCF6679),
      onError: Color(0xFF370B1E),
      surface: Color(0xFF121212),
      onSurface: Color(0xFFE2E2E2),
      surfaceContainerHighest: Color(0xFF2A2A2A),
      onSurfaceVariant: Color(0xFFB0BEC5),
      outline: Color(0xFF546E7A),
      shadow: Color(0xFF000000),
      inverseSurface: Color(0xFFE2E2E2),
      onInverseSurface: Color(0xFF121212),
      inversePrimary: Color(0xFF2E7D32),
      primaryContainer: Color(0xFF1B5E20),
      onPrimaryContainer: Color(0xFFC8E6C9),
      secondaryContainer: Color(0xFF0D47A1),
      onSecondaryContainer: Color(0xFFBBDEFB),
      tertiaryContainer: Color(0xFF263238),
      onTertiaryContainer: Color(0xFFB0BEC5),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1B1B1B),
        foregroundColor: Color(0xFFE2E2E2),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF4CAF50),
          side: const BorderSide(color: Color(0xFF4CAF50)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1E88E5))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Outty',
      theme: _buildTheme(),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          if (snapshot.hasData) {
            return UserOnboardingGate(user: snapshot.data!);
          }

          return const AuthScreen();
        },
      ),
    );
  }
}
