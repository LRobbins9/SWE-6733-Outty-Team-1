// BDD Feature: Instagram Handle
//
// Background: A signed-in user can add an Instagram handle during profile setup.
//
// Scenario covered:
//   - Entered handle is normalized and displayed on the profile screen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart' show UserCredential;
import 'package:outty/models/block_model.dart';
import 'package:outty/models/match_model.dart';
import 'package:outty/models/user_model.dart';
import 'package:outty/providers/auth_provider.dart';
import 'package:outty/providers/block_provider.dart';
import 'package:outty/providers/match_provider.dart';
import 'package:outty/screens/profile_setup_screen.dart';
import 'package:provider/provider.dart';

class _InstagramAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  UserModel? currentUser;

  @override
  bool isLoggedIn = true;

  @override
  bool isLoading = false;

  @override
  String? errorMessage;

  _InstagramAuthProvider({required this.currentUser});

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
  Future<UserCredential> signInWithGoogle() async {
    throw UnimplementedError();
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

class _InstagramMatchProvider extends ChangeNotifier implements MatchProvider {
  @override
  List<MatchModel> matches = [];

  @override
  List<BlockModel> blocks = [];

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

  @override
  BlockProvider get blockProvider {
    throw UnimplementedError();
  }
}

UserModel _baseUser() {
  return UserModel(
    id: 'user-ig-1',
    name: 'Alex Summit',
    age: 29,
    bio: 'Weekend hiker',
    email: 'alex@outty.app',
    adventureTypes: const ['Hiking'],
    skillLevel: 'Beginner',
  );
}

Widget _buildProfileSetup(_InstagramAuthProvider authProvider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<MatchProvider>.value(
        value: _InstagramMatchProvider(),
      ),
    ],
    child: const MaterialApp(
      routes: {
        '/home': _homeRouteBuilder,
      },
      home: ProfileSetupScreen(),
    ),
  );
}

Widget _homeRouteBuilder(BuildContext context) {
  return const Scaffold(body: Center(child: Text('HOME LANDING')));
}

Future<void> _completeEditFlow(WidgetTester tester) async {
  await tester.tap(find.text('NEXT'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('NEXT'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('FINISH'));
  await tester.pumpAndSettle();
}

void main() {
  group('Feature: Instagram Handle', () {
    group('Scenario: User adds an Instagram handle in profile setup', () {
      testWidgets(
        'Given the user enters a handle with spaces and @ prefix, '
        'When profile setup is finished, '
        'Then the saved handle is normalized',
        (tester) async {
          final authProvider = _InstagramAuthProvider(currentUser: _baseUser());

          await tester.pumpWidget(_buildProfileSetup(authProvider));
          await tester.enterText(
            find.bySemanticsLabel('Instagram Handle'),
            '  @summit.alex  ',
          );
          await tester.pumpAndSettle();

          await _completeEditFlow(tester);

          expect(authProvider.currentUser?.instagramHandle, 'summit.alex');
        },
      );

      testWidgets(
        'Given the user enters a handle without @ prefix, '
        'When profile setup is finished, '
        'Then the same handle value is saved',
        (tester) async {
          final authProvider = _InstagramAuthProvider(currentUser: _baseUser());

          await tester.pumpWidget(_buildProfileSetup(authProvider));
          await tester.enterText(
            find.bySemanticsLabel('Instagram Handle'),
            'summit.alex',
          );
          await tester.pumpAndSettle();

          await _completeEditFlow(tester);

          expect(authProvider.currentUser?.instagramHandle, 'summit.alex');
        },
      );

      testWidgets(
        'Given the user enters multiple @ prefixes and spaces, '
        'When profile setup is finished, '
        'Then all leading @ characters are removed before save',
        (tester) async {
          final authProvider = _InstagramAuthProvider(currentUser: _baseUser());

          await tester.pumpWidget(_buildProfileSetup(authProvider));
          await tester.enterText(
            find.bySemanticsLabel('Instagram Handle'),
            '   @@@peak.pal   ',
          );
          await tester.pumpAndSettle();

          await _completeEditFlow(tester);

          expect(authProvider.currentUser?.instagramHandle, 'peak.pal');
        },
      );

      testWidgets(
        'Given the user leaves the Instagram handle blank, '
        'When profile setup is finished, '
        'Then no Instagram handle is saved',
        (tester) async {
          final authProvider = _InstagramAuthProvider(
            currentUser: _baseUser().copyWith(instagramHandle: 'old.handle'),
          );

          await tester.pumpWidget(_buildProfileSetup(authProvider));
          await tester.enterText(
            find.bySemanticsLabel('Instagram Handle'),
            '   ',
          );
          await tester.pumpAndSettle();

          await _completeEditFlow(tester);

          expect(authProvider.currentUser?.instagramHandle, isNull);
        },
      );
    });
  });
}
