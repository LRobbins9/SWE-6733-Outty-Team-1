import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:outty/screens/account_management_screen.dart';

class _MockUser extends Mock implements User {}

class _MockUserInfo extends Mock implements UserInfo {}

void main() {
  Widget buildSubject(User user) {
    return MaterialApp(
      home: AccountManagementScreen(
        user: user,
        profileData: const {'name': 'Alex'},
      ),
    );
  }

  group('AccountManagementScreen provider-specific behavior', () {
    testWidgets(
      'password users can see email and password management fields',
      (tester) async {
        final user = _MockUser();
        final passwordProvider = _MockUserInfo();

        when(() => passwordProvider.providerId).thenReturn('password');
        when(() => user.providerData).thenReturn([passwordProvider]);
        when(() => user.email).thenReturn('password-user@outty.app');

        await tester.pumpWidget(buildSubject(user));

        final emailField = tester.widget<TextField>(
          find.widgetWithText(TextField, 'Email'),
        );
        expect(emailField.readOnly, isFalse);

        expect(
          find.widgetWithText(
            TextField,
            'Current password (required for changes)',
          ),
          findsOneWidget,
        );
        expect(find.widgetWithText(TextField, 'New password'), findsOneWidget);
        expect(
          find.widgetWithText(TextField, 'Confirm new password'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(TextField, 'Password to confirm deletion'),
          findsOneWidget,
        );
        expect(
          find.text('Email and password are managed by your Google account.'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'google users cannot see password management fields',
      (tester) async {
        final user = _MockUser();
        final googleProvider = _MockUserInfo();

        when(() => googleProvider.providerId).thenReturn('google.com');
        when(() => user.providerData).thenReturn([googleProvider]);
        when(() => user.email).thenReturn('google-user@outty.app');

        await tester.pumpWidget(buildSubject(user));

        final emailField = tester.widget<TextField>(
          find.widgetWithText(TextField, 'Email'),
        );
        expect(emailField.readOnly, isTrue);

        expect(
          find.widgetWithText(
            TextField,
            'Current password (required for changes)',
          ),
          findsNothing,
        );
        expect(find.widgetWithText(TextField, 'New password'), findsNothing);
        expect(
          find.widgetWithText(TextField, 'Confirm new password'),
          findsNothing,
        );
        expect(
          find.widgetWithText(TextField, 'Password to confirm deletion'),
          findsNothing,
        );
        expect(
          find.text('Email and password are managed by your Google account.'),
          findsOneWidget,
        );
        expect(
          find.text('You will confirm deletion with your Google account.'),
          findsOneWidget,
        );
      },
    );
  });
}
