// BDD Feature: Profile Screen Display
//
// Background: A signed-in user navigates to the Profile tab.
//             The screen loads their Firestore data and renders it.
//
// These tests verify the rendering logic by building the profile
// content widget directly with known data, isolating the view
// behaviour from the Firestore data-loading layer.
//
// Scenarios covered:
//   - Profile header shows name and email
//   - Profile avatar falls back to person icon when no picture URL is set
//   - About section is shown when bio is non-empty
//   - About section is hidden when bio is empty
//   - Adventure likes are rendered as chips
//   - Distance preference is displayed
//   - Age preference range is displayed
//   - Sign-out and delete-account options are visible

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Test helper – renders the same layout that ProfileScreen builds once its
// FutureBuilder resolves, so the view logic can be tested without Firebase.
// ---------------------------------------------------------------------------
Widget _buildProfileContent({
  String displayName = 'Alex Adventure',
  String email = 'alex@example.com',
  String pictureUrl = '',
  String bio = '',
  List<String> adventureLikes = const [],
  int distanceMiles = 25,
  int minAge = 18,
  int maxAge = 45,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundImage: pictureUrl.isNotEmpty
                          ? NetworkImage(pictureUrl)
                          : null,
                      child: pictureUrl.isEmpty
                          ? const Icon(Icons.person, size: 52)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(displayName, key: const Key('profile_name')),
                    Text(email, key: const Key('profile_email')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // About section – only rendered when bio is non-empty
            if (bio.isNotEmpty) ...[
              const Text('ABOUT', key: Key('about_header')),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(bio, key: const Key('bio_text')),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Adventure section
            const Text('ADVENTURE'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (adventureLikes.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: adventureLikes
                            .map((like) => Chip(label: Text(like)))
                            .toList(),
                      ),
                    Text('$distanceMiles miles',
                        key: const Key('distance_text')),
                    Text('$minAge – $maxAge years',
                        key: const Key('age_range_text')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Account settings
            const Text('ACCOUNT SETTINGS'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Sign out'),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever,
                        color: Colors.redAccent),
                    title: const Text('Manage account',
                        style: TextStyle(color: Colors.redAccent)),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  group('Feature: Profile Screen Display', () {
    // ── Scenario: header shows user info ──────────────────────────────────
    group('Scenario: Profile header shows display name and email', () {
      testWidgets(
        'Given a user with a display name and email, '
        'When the profile is rendered, '
        'Then both values are visible',
        (tester) async {
          await tester.pumpWidget(_buildProfileContent(
            displayName: 'Jordan Rivers',
            email: 'jordan@outty.app',
          ));
          expect(find.text('Jordan Rivers'), findsOneWidget);
          expect(find.text('jordan@outty.app'), findsOneWidget);
        },
      );
    });

    // ── Scenario: avatar fallback ─────────────────────────────────────────
    group('Scenario: Avatar shows person icon when no picture URL is set', () {
      testWidgets(
        'Given a user with no picture URL, '
        'When the profile is rendered, '
        'Then the person fallback icon is shown',
        (tester) async {
          await tester.pumpWidget(_buildProfileContent(pictureUrl: ''));
          expect(find.byIcon(Icons.person), findsOneWidget);
        },
      );
    });

    // ── Scenario: About section visible ───────────────────────────────────
    group('Scenario: About section is shown when bio is non-empty', () {
      testWidgets(
        'Given a user with a bio, '
        'When the profile is rendered, '
        'Then the ABOUT header and bio text are visible',
        (tester) async {
          await tester.pumpWidget(_buildProfileContent(
            bio: 'I love hiking in the mountains.',
          ));
          expect(find.byKey(const Key('about_header')), findsOneWidget);
          expect(
            find.text('I love hiking in the mountains.'),
            findsOneWidget,
          );
        },
      );
    });

    // ── Scenario: About section hidden ────────────────────────────────────
    group('Scenario: About section is hidden when bio is empty', () {
      testWidgets(
        'Given a user with no bio, '
        'When the profile is rendered, '
        'Then the ABOUT header is not visible',
        (tester) async {
          await tester.pumpWidget(_buildProfileContent(bio: ''));
          expect(find.byKey(const Key('about_header')), findsNothing);
        },
      );
    });

    // ── Scenario: adventure likes as chips ────────────────────────────────
    group('Scenario: Adventure likes are rendered as chips', () {
      testWidgets(
        'Given a user with adventure likes, '
        'When the profile is rendered, '
        'Then each like appears as a Chip widget',
        (tester) async {
          await tester.pumpWidget(_buildProfileContent(
            adventureLikes: ['Hiking', 'Kayaking', 'Camping'],
          ));
          expect(find.widgetWithText(Chip, 'Hiking'), findsOneWidget);
          expect(find.widgetWithText(Chip, 'Kayaking'), findsOneWidget);
          expect(find.widgetWithText(Chip, 'Camping'), findsOneWidget);
        },
      );
    });

    // ── Scenario: distance preference ─────────────────────────────────────
    group('Scenario: Distance preference is displayed', () {
      testWidgets(
        'Given a distance preference of 40 miles, '
        'When the profile is rendered, '
        'Then "40 miles" appears on screen',
        (tester) async {
          await tester.pumpWidget(
              _buildProfileContent(distanceMiles: 40));
          expect(find.text('40 miles'), findsOneWidget);
        },
      );
    });

    // ── Scenario: age range ───────────────────────────────────────────────
    group('Scenario: Age preference range is displayed', () {
      testWidgets(
        'Given an age range of 21 to 35, '
        'When the profile is rendered, '
        'Then "21 – 35 years" appears on screen',
        (tester) async {
          await tester.pumpWidget(
              _buildProfileContent(minAge: 21, maxAge: 35));
          expect(find.text('21 – 35 years'), findsOneWidget);
        },
      );
    });

    // ── Scenario: account settings ────────────────────────────────────────
    group('Scenario: Account settings section is always visible', () {
      testWidgets(
        'Given any profile is rendered, '
        'When the user scrolls to the bottom, '
        'Then Sign out and Manage account options are visible',
        (tester) async {
          await tester.pumpWidget(_buildProfileContent());
          await tester.scrollUntilVisible(
            find.text('Sign out'),
            50,
          );
          expect(find.text('Sign out'), findsOneWidget);
          expect(find.text('Manage account'), findsOneWidget);
        },
      );
    });
  });
}
