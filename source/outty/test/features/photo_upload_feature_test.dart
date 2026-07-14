// BDD Feature: Photo Upload Experience
//
// Background: A signed-in user can manage one compressed profile photo
//             during profile setup and from the profile screen.
//
// These tests verify the photo-upload entry points and visible state
// without depending on Firebase, image picker plugins, or network image IO.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outty/models/match_model.dart';
import 'package:outty/models/user_model.dart';
import 'package:outty/providers/auth_provider.dart';
import 'package:outty/providers/match_provider.dart';
import 'package:outty/screens/profile_screen.dart';
import 'package:outty/screens/profile_setup_screen.dart';
import 'package:outty/widgets/user_avatar.dart';
import 'package:provider/provider.dart';

class _PhotoFeatureAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  UserModel? currentUser;

  @override
  bool isLoggedIn = true;

  @override
  bool isLoading = false;

  @override
  String? errorMessage;

  _PhotoFeatureAuthProvider({required this.currentUser});

  @override
  void clearError() {}

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

class _PhotoFeatureMatchProvider extends ChangeNotifier
    implements MatchProvider {
  @override
  List<MatchModel> matches = [];

  @override
  List<UserModel> feed = [];

  @override
  bool isLoading = false;

  @override
  bool feedExhausted = false;

  @override
  Future<UserModel?> getUserById(String id) async {
    return null;
  }

  @override
  Future<void> load(UserModel currentUser) async {}

  @override
  Future<void> resetFeed(UserModel currentUser) async {}

  @override
  Future<void> swipeLeft(String currentUserId, String candidateId) async {}

  @override
  Future<MatchModel?> swipeRight(
    UserModel currentUser,
    UserModel candidate,
  ) async {
    return null;
  }

  @override
  Future<void> updateLastMessage(String matchId, String message) async {}

  @override
  Future<void> markAsRead(String matchId, String userId) async {}
}

UserModel _buildUser({String? photoUrl}) {
  return UserModel(
    id: 'user-1',
    name: 'Alex Summit',
    age: 29,
    bio: 'Weekend hiker',
    email: 'alex@outty.app',
    location: 'Atlanta',
    targetAgeStart: 24,
    targetAgeEnd: 35,
    gender: 'Male',
    interestedIn: 'Any',
    adventureTypes: const ['Hiking', 'Camping'],
    skillLevel: 'Beginner',
    photoUrl: photoUrl,
  );
}

Widget _buildProfileSetupApp(_PhotoFeatureAuthProvider authProvider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<MatchProvider>.value(
        value: _PhotoFeatureMatchProvider(),
      ),
    ],
    child: const MaterialApp(home: ProfileSetupScreen()),
  );
}

Widget _buildProfileScreenApp(_PhotoFeatureAuthProvider authProvider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<MatchProvider>.value(
        value: _PhotoFeatureMatchProvider(),
      ),
    ],
    child: const MaterialApp(home: ProfileScreen()),
  );
}

void main() {
  group('Feature: Photo Upload Experience', () {
    group('Scenario: Profile setup offers photo upload to a new user', () {
      testWidgets(
        'Given a signed-in user with no profile photo, '
        'When profile setup is shown, '
        'Then the screen offers an Upload Photo action and one-photo guidance',
        (tester) async {
          final authProvider = _PhotoFeatureAuthProvider(
            currentUser: _buildUser(photoUrl: null),
          );

          await tester.pumpWidget(_buildProfileSetupApp(authProvider));
          await tester.pumpAndSettle();

          expect(find.text('Upload Photo'), findsOneWidget);
          expect(
            find.text('Optional. One compressed photo only.'),
            findsOneWidget,
          );
          expect(find.byType(UserAvatar), findsOneWidget);
        },
      );
    });

    group('Scenario: Profile setup lets an existing user replace a photo', () {
      testWidgets('Given a signed-in user with an existing profile photo, '
          'When profile setup is shown, '
          'Then the action changes from Upload Photo to Change Photo', (
        tester,
      ) async {
        final authProvider = _PhotoFeatureAuthProvider(
          currentUser: _buildUser(photoUrl: 'https://example.com/profile.png'),
        );

        await tester.pumpWidget(_buildProfileSetupApp(authProvider));
        await tester.pumpAndSettle();

        expect(find.text('Change Photo'), findsOneWidget);
        expect(find.text('Upload Photo'), findsNothing);
      });
    });

    group('Scenario: Profile screen keeps photo controls outside the header', () {
      testWidgets(
        'Given a signed-in user on the profile screen, '
        'When the screen is rendered, '
        'Then the upload action and helper text appear below the profile title',
        (tester) async {
          final authProvider = _PhotoFeatureAuthProvider(
            currentUser: _buildUser(
              photoUrl: 'https://example.com/profile.png',
            ),
          );

          await tester.pumpWidget(_buildProfileScreenApp(authProvider));
          await tester.pumpAndSettle();

          final title = find.text('Alex Summit');
          final uploadButton = find.text('Upload Photo');
          final helperText = find.text('One compressed profile photo');

          expect(title, findsOneWidget);
          expect(uploadButton, findsOneWidget);
          expect(helperText, findsOneWidget);
          expect(find.byType(UserAvatar), findsOneWidget);
          expect(
            tester.getTopLeft(uploadButton).dy,
            greaterThan(tester.getBottomLeft(title).dy),
          );
          expect(
            tester.getTopLeft(helperText).dy,
            greaterThan(tester.getBottomLeft(uploadButton).dy),
          );
        },
      );
    });

    group('Scenario: Profile screen prevents duplicate uploads while busy', () {
      testWidgets(
        'Given a profile photo upload is already in progress, '
        'When the profile screen is rendered, '
        'Then the upload button is disabled and a loading indicator is shown',
        (tester) async {
          final authProvider = _PhotoFeatureAuthProvider(
            currentUser: _buildUser(photoUrl: null),
          )..isLoading = true;

          await tester.pumpWidget(_buildProfileScreenApp(authProvider));
          await tester.pump();

          final uploadButton = tester.widget<OutlinedButton>(
            find.byType(OutlinedButton),
          );

          expect(uploadButton.onPressed, isNull);
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        },
      );
    });
  });
}
