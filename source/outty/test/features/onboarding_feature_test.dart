// BDD Feature: User Onboarding
//
// Background: A signed-in user who has not yet completed their profile
//             is presented with the three-step onboarding screen.
//
// Scenarios covered:
//   - Step 0 (Profile) validation blocks empty name / age
//   - Step 0 advances when name and age are filled
//   - Step 1 (Adventure Likes) validation blocks empty selection
//   - Step 1 advances when at least one like is chosen
//   - Progress indicator starts at the first step
//   - All seven adventure-like chips are rendered
//   - Picture URL field is visible on step 0
//   - Bio field is visible on step 0

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:outty/screens/onboarding_screen.dart';

class _MockUser extends Mock implements User {}

void main() {
  late _MockUser mockUser;

  setUp(() {
    mockUser = _MockUser();
    when(() => mockUser.uid).thenReturn('test-uid-001');
    when(() => mockUser.email).thenReturn('tester@example.com');
    when(() => mockUser.displayName).thenReturn(null);
  });

  Widget buildSubject() => MaterialApp(
        home: OnboardingScreen(
          user: mockUser,
          onComplete: () {},
        ),
      );

  // ─────────────────────────────────────────────────────────────────────────
  group('Feature: User Onboarding', () {
    // ── Scenario: initial state ───────────────────────────────────────────
    group('Scenario: Step 0 (Profile) is shown on launch', () {
      testWidgets(
        'Given the onboarding screen opens, '
        'When step 0 is rendered, '
        'Then the name and age fields are visible',
        (tester) async {
          await tester.pumpWidget(buildSubject());
          expect(find.text('Name'), findsOneWidget);
          expect(find.text('Age'), findsOneWidget);
        },
      );

      testWidgets(
        'Given step 0 is rendered, '
        'When the user views the form, '
        'Then the profile-picture URL field is visible',
        (tester) async {
          await tester.pumpWidget(buildSubject());
          expect(find.text('Profile picture URL (optional)'), findsOneWidget);
        },
      );

      testWidgets(
        'Given step 0 is rendered, '
        'When the user views the form, '
        'Then the bio field is visible',
        (tester) async {
          await tester.pumpWidget(buildSubject());
          expect(find.text('Short bio'), findsOneWidget);
        },
      );

      testWidgets(
        'Given step 0 is rendered, '
        'When the user views the progress bar, '
        'Then a LinearProgressIndicator is present',
        (tester) async {
          await tester.pumpWidget(buildSubject());
          expect(find.byType(LinearProgressIndicator), findsOneWidget);
        },
      );
    });

    // ── Scenario: step 0 → validation ────────────────────────────────────
    group('Scenario: Step 0 blocks progression when fields are empty', () {
      testWidgets(
        'Given name and age are both empty, '
        'When Continue is tapped, '
        'Then an error snackbar is shown and the step does not advance',
        (tester) async {
          await tester.pumpWidget(buildSubject());
          await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
          await tester.pumpAndSettle();
          expect(
            find.text('Please enter your name and age.'),
            findsOneWidget,
          );
          // Still on step 0 – adventure likes are NOT visible
          expect(find.text('Pick your adventure likes'), findsNothing);
        },
      );

      testWidgets(
        'Given only the age is empty, '
        'When Continue is tapped, '
        'Then the error snackbar is shown',
        (tester) async {
          await tester.pumpWidget(buildSubject());
          await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Alex');
          await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
          await tester.pumpAndSettle();
          expect(find.text('Please enter your name and age.'), findsOneWidget);
        },
      );
    });

    // ── Scenario: step 0 → advance ────────────────────────────────────────
    group('Scenario: Step 0 advances when name and age are provided', () {
      testWidgets(
        'Given name and age are filled, '
        'When Continue is tapped, '
        'Then step 1 (adventure likes) is shown',
        (tester) async {
          await tester.pumpWidget(buildSubject());
          await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Alex');
          await tester.enterText(find.widgetWithText(TextField, 'Age'), '28');
          await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
          await tester.pumpAndSettle();
          expect(find.text('Pick your adventure likes'), findsOneWidget);
        },
      );
    });

    // ── Scenario: step 1 chips ────────────────────────────────────────────
    group('Scenario: Step 1 shows adventure-like chips', () {
      Future<void> goToStep1(WidgetTester tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Alex');
        await tester.enterText(find.widgetWithText(TextField, 'Age'), '28');
        await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
        await tester.pumpAndSettle();
      }

      testWidgets(
        'Given step 1 is shown, '
        'When the user views the chips, '
        'Then all seven activity options are visible',
        (tester) async {
          await goToStep1(tester);
          for (final activity in [
            'Hiking',
            'Camping',
            'Cycling',
            'Kayaking',
            'Climbing',
            'Backpacking',
            'Traveling',
          ]) {
            expect(find.text(activity), findsOneWidget);
          }
        },
      );
    });

    // ── Scenario: step 1 → validation ────────────────────────────────────
    group('Scenario: Step 1 blocks progression when no activity chosen', () {
      testWidgets(
        'Given no adventure like is selected, '
        'When Continue is tapped, '
        'Then an error snackbar is shown and step 2 is not visible',
        (tester) async {
          await tester.pumpWidget(buildSubject());
          // Advance to step 1
          await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Alex');
          await tester.enterText(find.widgetWithText(TextField, 'Age'), '28');
          await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
          await tester.pumpAndSettle();

          // Tap Continue without selecting a like
          await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
          await tester.pumpAndSettle();

          expect(
            find.text('Select at least one adventure like.'),
            findsOneWidget,
          );
          expect(find.text('Customize your matches'), findsNothing);
        },
      );
    });

    // ── Scenario: step 1 → advance ────────────────────────────────────────
    group('Scenario: Step 1 advances when at least one activity is chosen', () {
      testWidgets(
        'Given one adventure like is selected, '
        'When Continue is tapped, '
        'Then step 2 (matching preferences) is shown',
        (tester) async {
          await tester.pumpWidget(buildSubject());
          // Step 0 → 1
          await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Alex');
          await tester.enterText(find.widgetWithText(TextField, 'Age'), '28');
          await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
          await tester.pumpAndSettle();

          // Select one chip
          await tester.tap(find.widgetWithText(FilterChip, 'Hiking'));
          await tester.pump();

          // Step 1 → 2
          await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
          await tester.pumpAndSettle();

          expect(find.text('Customize your matches'), findsOneWidget);
        },
      );
    });

    // ── Scenario: step 2 content ──────────────────────────────────────────
    group('Scenario: Step 2 (Matching) shows distance and age sliders', () {
      testWidgets(
        'Given step 2 is shown, '
        'When the user views the screen, '
        'Then distance and age range sliders are present',
        (tester) async {
          await tester.pumpWidget(buildSubject());
          // Step 0 → 1
          await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Alex');
          await tester.enterText(find.widgetWithText(TextField, 'Age'), '28');
          await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
          await tester.pumpAndSettle();
          // Step 1 → 2
          await tester.tap(find.widgetWithText(FilterChip, 'Hiking'));
          await tester.pump();
          await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
          await tester.pumpAndSettle();

          expect(find.byType(Slider), findsOneWidget);
          expect(find.byType(RangeSlider), findsOneWidget);
        },
      );
    });

    // ── Scenario: back button on step 1 ──────────────────────────────────
    group('Scenario: Back button returns to previous step', () {
      testWidgets(
        'Given step 1 is shown, '
        'When Back is tapped, '
        'Then step 0 is shown again',
        (tester) async {
          await tester.pumpWidget(buildSubject());
          await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Alex');
          await tester.enterText(find.widgetWithText(TextField, 'Age'), '28');
          await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
          await tester.pumpAndSettle();

          await tester.tap(find.widgetWithText(OutlinedButton, 'Back'));
          await tester.pumpAndSettle();

          expect(find.text('Name'), findsOneWidget);
          expect(find.text('Pick your adventure likes'), findsNothing);
        },
      );
    });
  });
}
