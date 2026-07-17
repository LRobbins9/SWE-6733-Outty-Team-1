// BDD Feature: Single Sign-On (Google)
//
// Background: A returning user can use Google sign-in from the login screen.
//
// Scenario covered:
//   - Google SSO invokes AuthProvider and routes an incomplete profile to setup.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart' show UserCredential;
import 'package:mocktail/mocktail.dart';
import 'package:outty/models/user_model.dart';
import 'package:outty/providers/auth_provider.dart';
import 'package:outty/screens/auth_screens.dart';
import 'package:outty/utils/constants.dart';
import 'package:provider/provider.dart';

class _MockUserCredential extends Mock implements UserCredential {}

class _SsoAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  UserModel? currentUser;

  @override
  bool isLoggedIn = false;

  @override
  bool isLoading = false;

  @override
  String? errorMessage;

  int signInWithGoogleCalls = 0;
  UserModel? userAfterGoogle;
  bool shouldThrowOnGoogleSignIn;

  _SsoAuthProvider({
    this.userAfterGoogle,
    this.shouldThrowOnGoogleSignIn = false,
  });

  @override
  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  @override
  Future<void> deleteProfilePhotosForUser(String uid) async {}

  @override
  Future<bool> login({required String email, required String password}) async {
    return true;
  }

  @override
  Future<void> logout() async {}

  @override
  Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) async {
    return true;
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    signInWithGoogleCalls += 1;
    if (shouldThrowOnGoogleSignIn) {
      errorMessage = 'Google sign-in failed.';
      notifyListeners();
      throw Exception('Google sign-in failed');
    }

    currentUser =
        userAfterGoogle ??
        UserModel(
          id: 'google-user-1',
          name: 'Google Adventurer',
          age: 0,
          bio: '',
          email: 'google.user@example.com',
          adventureTypes: const [],
          skillLevel: 'Beginner',
        );
    isLoggedIn = true;
    notifyListeners();
    return _MockUserCredential();
  }

  @override
  Future<void> tryRestoreSession() async {}

  @override
  Future<String?> uploadProfilePhoto() async {
    return null;
  }

  @override
  Future<void> updateCurrentUser(UserModel updated) async {
    currentUser = updated;
    notifyListeners();
  }
}

void main() {
  Widget buildSubject(_SsoAuthProvider authProvider) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ],
      child: MaterialApp(
        routes: {
          AppRoutes.profileSetup: (_) => const Scaffold(
                body: Center(child: Text('PROFILE SETUP LANDING')),
              ),
          AppRoutes.home: (_) => const Scaffold(
                body: Center(child: Text('HOME LANDING')),
              ),
        },
        home: const LoginScreen(),
      ),
    );
  }

  group('Feature: Single Sign-On (Google)', () {
    group('Scenario: User signs in with Google from Login screen', () {
      testWidgets(
        'Given login screen is visible and profile is incomplete, '
        'When the user taps Sign in with Google, '
        'Then SSO is requested and the user is routed to profile setup',
        (tester) async {
          final authProvider = _SsoAuthProvider();

          await tester.pumpWidget(buildSubject(authProvider));
          expect(find.text('Sign in with Google'), findsOneWidget);

          await tester.tap(find.text('Sign in with Google'));
          await tester.pumpAndSettle();

          expect(authProvider.signInWithGoogleCalls, 1);
          expect(find.text('PROFILE SETUP LANDING'), findsOneWidget);
        },
      );

      testWidgets(
        'Given login screen is visible and profile is already complete, '
        'When the user taps Sign in with Google, '
        'Then the user is routed to home',
        (tester) async {
          final authProvider = _SsoAuthProvider(
            userAfterGoogle: UserModel(
              id: 'google-user-2',
              name: 'Trail Friend',
              age: 29,
              bio: 'Always outdoors',
              email: 'trail.friend@example.com',
              adventureTypes: const ['Hiking'],
              skillLevel: 'Intermediate',
            ),
          );

          await tester.pumpWidget(buildSubject(authProvider));
          await tester.tap(find.text('Sign in with Google'));
          await tester.pumpAndSettle();

          expect(authProvider.signInWithGoogleCalls, 1);
          expect(find.text('HOME LANDING'), findsOneWidget);
        },
      );

      testWidgets(
        'Given login screen is visible and Google sign-in fails, '
        'When the user taps Sign in with Google, '
        'Then an error snackbar is shown and no route change occurs',
        (tester) async {
          final authProvider = _SsoAuthProvider(shouldThrowOnGoogleSignIn: true);

          await tester.pumpWidget(buildSubject(authProvider));
          await tester.tap(find.text('Sign in with Google'));
          await tester.pumpAndSettle();

          expect(authProvider.signInWithGoogleCalls, 1);
          expect(find.text('Google sign-in failed.'), findsWidgets);
          expect(find.text('PROFILE SETUP LANDING'), findsNothing);
          expect(find.text('HOME LANDING'), findsNothing);
        },
      );

      testWidgets(
        'Given login screen is visible, '
        'When the screen is rendered, '
        'Then the Sign in with Google action is present',
        (tester) async {
          final authProvider = _SsoAuthProvider();

          await tester.pumpWidget(buildSubject(authProvider));

          expect(find.text('Sign in with Google'), findsOneWidget);
        },
      );
    });
  });
}
