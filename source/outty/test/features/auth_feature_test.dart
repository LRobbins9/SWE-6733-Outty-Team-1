// BDD Feature: User Authentication
//
// Background: The user opens the app and is not signed in.
//
// Scenarios covered:
//   - Email field validation
//   - Password field validation
//   - Password confirmation mismatch (sign-up)
//   - Toggle between sign-in and sign-up modes
//   - Sign-in form has correct initial label

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outty/screens/auth_screen.dart';

void main() {
  // Helper: renders AuthScreen inside a minimal app shell.
  Widget buildSubject() => const MaterialApp(home: AuthScreen());

  // ─────────────────────────────────────────────────────────────────────────
  group('Feature: User Authentication', () {
    // ── Scenario: form is shown in sign-in mode by default ────────────────
    group('Scenario: App opens auth screen in sign-in mode', () {
      testWidgets(
        'Given the app launches, '
        'When the auth screen is displayed, '
        'Then the sign-in label and email field are visible',
        (tester) async {
          await tester.pumpWidget(buildSubject());
          expect(find.text('Sign in to Outty'), findsOneWidget);
          expect(find.text('Email'), findsOneWidget);
          expect(find.text('Password'), findsOneWidget);
        },
      );

      testWidgets(
        'Given the sign-in mode, '
        'When the screen is displayed, '
        'Then no confirm-password field is visible',
        (tester) async {
          await tester.pumpWidget(buildSubject());
          expect(find.text('Confirm password'), findsNothing);
        },
      );
    });

    // ── Scenario: toggle to create-account mode ───────────────────────────
    group('Scenario: User switches to create-account mode', () {
      testWidgets(
        'Given sign-in mode, '
        'When the "Create account" link is tapped, '
        'Then the confirm-password field becomes visible',
        (tester) async {
          await tester.pumpWidget(buildSubject());
          await tester.ensureVisible(
            find.widgetWithText(TextButton, 'Create account'),
          );
          await tester.tap(find.widgetWithText(TextButton, 'Create account'));
          await tester.pumpAndSettle();
          expect(find.text('Confirm password'), findsOneWidget);
        },
      );

      testWidgets(
        'Given create-account mode, '
        'When the "Already have an account?" link is tapped, '
        'Then the confirm-password field disappears',
        (tester) async {
          await tester.pumpWidget(buildSubject());
          // Switch to create mode
          await tester.ensureVisible(
            find.widgetWithText(TextButton, 'Create account'),
          );
          await tester.tap(find.widgetWithText(TextButton, 'Create account'));
          await tester.pumpAndSettle();
          // Scroll to bring the toggle button on screen before tapping
          await tester.ensureVisible(
            find.widgetWithText(TextButton, 'Already have an account?'),
          );
          await tester.tap(find.widgetWithText(TextButton, 'Already have an account?'));
          await tester.pumpAndSettle();
          expect(find.text('Confirm password'), findsNothing);
        },
      );
    });

    // ── Scenario: email validation ────────────────────────────────────────
    group('Scenario: User submits without entering an email', () {
      testWidgets(
        'Given an empty email field, '
        'When the sign-in button is tapped, '
        'Then an email validation error is shown',
        (tester) async {
          await tester.pumpWidget(buildSubject());
          await tester.ensureVisible(
            find.widgetWithText(FilledButton, 'Sign in'),
          );
          await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
          await tester.pumpAndSettle();
          expect(find.text('Please enter your email.'), findsOneWidget);
        },
      );
    });

    // ── Scenario: password validation ─────────────────────────────────────
    group('Scenario: User submits without entering a password', () {
      testWidgets(
        'Given a valid email but empty password, '
        'When the sign-in button is tapped, '
        'Then a password validation error is shown',
        (tester) async {
          await tester.pumpWidget(buildSubject());
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Email'),
            'user@example.com',
          );
          await tester.ensureVisible(
            find.widgetWithText(FilledButton, 'Sign in'),
          );
          await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
          await tester.pumpAndSettle();
          expect(find.text('Please enter your password.'), findsOneWidget);
        },
      );
    });

    // ── Scenario: short password in sign-up mode ──────────────────────────
    group('Scenario: User enters too-short a password during sign-up', () {
      testWidgets(
        'Given sign-up mode and a password shorter than 6 characters, '
        'When the create-account button is tapped, '
        'Then a minimum-length error is shown',
        (tester) async {
          await tester.pumpWidget(buildSubject());
          // Switch to create-account mode
          await tester.ensureVisible(
            find.widgetWithText(TextButton, 'Create account'),
          );
          await tester.tap(find.widgetWithText(TextButton, 'Create account'));
          await tester.pumpAndSettle();

          await tester.enterText(
            find.widgetWithText(TextFormField, 'Email'),
            'user@example.com',
          );
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Password'),
            'abc',
          );
          await tester.ensureVisible(
            find.widgetWithText(FilledButton, 'Create account'),
          );
          await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
          await tester.pumpAndSettle();
          expect(
            find.text('Password must be at least 6 characters.'),
            findsOneWidget,
          );
        },
      );
    });

    // ── Scenario: confirm-password blank during sign-up ───────────────────
    group('Scenario: User leaves confirm-password blank during sign-up', () {
      testWidgets(
        'Given sign-up mode with email and password filled, '
        'When confirm-password is left empty and button tapped, '
        'Then a confirm-password validation error is shown',
        (tester) async {
          await tester.pumpWidget(buildSubject());
          await tester.ensureVisible(
            find.widgetWithText(TextButton, 'Create account'),
          );
          await tester.tap(find.widgetWithText(TextButton, 'Create account'));
          await tester.pumpAndSettle();

          await tester.enterText(
            find.widgetWithText(TextFormField, 'Email'),
            'user@example.com',
          );
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Password'),
            'password123',
          );
          await tester.ensureVisible(
            find.widgetWithText(FilledButton, 'Create account'),
          );
          await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
          await tester.pumpAndSettle();
          expect(
            find.text('Please confirm your password.'),
            findsOneWidget,
          );
        },
      );
    });
  });
}
