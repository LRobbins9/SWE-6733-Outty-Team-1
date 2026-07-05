// BDD Feature: Hub Navigation
//
// Background: A signed-in user who has completed onboarding is shown
//             the hub screen with a side navigation rail.
//
// Scenarios covered:
//   - Default selected tab is Discover (index 0)
//   - All four navigation destinations are rendered
//   - Tapping a destination changes the active tab title
//   - Sign-out button is present in the app bar

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:outty/screens/hub_screen.dart';

class _MockUser extends Mock implements User {}

void main() {
  late _MockUser mockUser;

  setUp(() {
    mockUser = _MockUser();
    when(() => mockUser.uid).thenReturn('hub-test-uid');
    when(() => mockUser.email).thenReturn('hub@example.com');
    when(() => mockUser.displayName).thenReturn('Hub Tester');
  });

  Widget buildSubject() => MaterialApp(home: HubScreen(user: mockUser));

  // ─────────────────────────────────────────────────────────────────────────
  group('Feature: Hub Navigation', () {
    // ── Scenario: navigation rail ─────────────────────────────────────────
    group('Scenario: All navigation destinations are visible', () {
      testWidgets(
        'Given the hub screen is shown, '
        'When the navigation rail is rendered, '
        'Then Discover, Matches, Messages and Profile labels are present',
        (tester) async {
          await tester.pumpWidget(buildSubject());
          expect(find.text('Discover'), findsWidgets);
          expect(find.text('Matches'), findsWidgets);
          expect(find.text('Messages'), findsWidgets);
          expect(find.text('Profile'), findsWidgets);
        },
      );

      testWidgets(
        'Given the hub screen is shown, '
        'When the user views it, '
        'Then a NavigationRail widget is present',
        (tester) async {
          await tester.pumpWidget(buildSubject());
          expect(find.byType(NavigationRail), findsOneWidget);
        },
      );
    });

    // ── Scenario: default selected tab ────────────────────────────────────
    group('Scenario: Discover is the default active tab', () {
      testWidgets(
        'Given the hub launches, '
        'When no tab has been tapped, '
        'Then the app bar title reads "Discover"',
        (tester) async {
          await tester.pumpWidget(buildSubject());
          // App bar title is Text widget inside AppBar
          expect(
            find.descendant(
              of: find.byType(AppBar),
              matching: find.text('Discover'),
            ),
            findsOneWidget,
          );
        },
      );
    });

    // ── Scenario: tab switching ────────────────────────────────────────────
    group('Scenario: Tapping a tab updates the active title', () {
      testWidgets(
        'Given the hub is on Discover, '
        'When the Matches destination is tapped, '
        'Then the app bar title changes to "Matches"',
        (tester) async {
          await tester.pumpWidget(buildSubject());

          // Tap the 'Matches' label inside the NavigationRail.
          await tester.tap(
            find.descendant(
              of: find.byType(NavigationRail),
              matching: find.text('Matches'),
            ).first,
          );
          await tester.pumpAndSettle();

          expect(
            find.descendant(
              of: find.byType(AppBar),
              matching: find.text('Matches'),
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'Given the hub is on Discover, '
        'When the Messages destination is tapped, '
        'Then the app bar title changes to "Messages"',
        (tester) async {
          await tester.pumpWidget(buildSubject());
          await tester.tap(
            find.descendant(
              of: find.byType(NavigationRail),
              matching: find.text('Messages'),
            ).first,
          );
          await tester.pumpAndSettle();

          expect(
            find.descendant(
              of: find.byType(AppBar),
              matching: find.text('Messages'),
            ),
            findsOneWidget,
          );
        },
      );
    });

    // ── Scenario: sign-out button ─────────────────────────────────────────
    group('Scenario: Sign-out button is accessible from the hub', () {
      testWidgets(
        'Given the hub screen is shown, '
        'When the user looks at the app bar, '
        'Then a sign-out icon button is visible',
        (tester) async {
          await tester.pumpWidget(buildSubject());
          expect(
            find.widgetWithIcon(IconButton, Icons.logout),
            findsOneWidget,
          );
        },
      );
    });
  });
}
