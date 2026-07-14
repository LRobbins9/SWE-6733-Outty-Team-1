import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outty/models/match_model.dart';
import 'package:outty/models/user_model.dart';
import 'package:outty/providers/auth_provider.dart';
import 'package:outty/providers/match_provider.dart';
import 'package:outty/screens/profile_setup_screen.dart';
import 'package:provider/provider.dart';

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  UserModel? currentUser;

  @override
  bool isLoggedIn = true;

  @override
  bool isLoading = false;

  @override
  String? errorMessage;

  FakeAuthProvider({this.currentUser});

  @override
  Future<bool> login({required String email, required String password}) async {
    return true;
  }

  @override
  Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) async {
    return true;
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> deleteProfilePhotosForUser(String uid) async {}

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

  @override
  void clearError() {}
}

class FakeMatchProvider extends ChangeNotifier implements MatchProvider {
  @override
  List<MatchModel> matches = [];

  @override
  List<UserModel> feed = [];

  @override
  bool isLoading = false;

  @override
  Future<void> markAsRead(String matchId, String userId) async {}

  @override
  bool feedExhausted = false;

  @override
  Future<void> load(UserModel user) async {}

  @override
  Future<UserModel?> getUserById(String id) async {
    return null;
  }

  @override
  Future<void> resetFeed(UserModel currentUser) async {}

  @override
  Future<MatchModel?> swipeRight(
    UserModel currentUser,
    UserModel candidate,
  ) async {
    return null;
  }

  @override
  Future<void> swipeLeft(String currentUserId, String candidateId) async {}

  @override
  Future<void> updateLastMessage(String matchId, String message) async {}
}

UserModel createTestUser() {
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
    adventureTypes: ['Hiking', 'Camping'],
    skillLevel: 'Beginner',
  );
}

void main() {
  testWidgets('edit mode allows navigating back to the previous step', (
    tester,
  ) async {
    final authProvider = FakeAuthProvider(currentUser: createTestUser());
    final matchProvider = FakeMatchProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<MatchProvider>.value(value: matchProvider),
        ],
        child: const MaterialApp(home: ProfileSetupScreen(isEditing: true)),
      ),
    );

    expect(find.text('Edit Your Profile'), findsOneWidget);
    expect(find.text('Adventurer Essentials'), findsOneWidget);
    expect(find.text('BACK'), findsNothing);
    expect(find.text('NEXT'), findsOneWidget);

    await tester.tap(find.text('NEXT'));
    await tester.pumpAndSettle();

    expect(find.text('Identity & Preferences'), findsOneWidget);
    expect(find.text('BACK'), findsOneWidget);
    expect(find.text('NEXT'), findsOneWidget);

    await tester.tap(find.text('BACK'));
    await tester.pumpAndSettle();

    expect(find.text('Adventurer Essentials'), findsOneWidget);
    expect(find.text('Identity & Preferences'), findsNothing);
  });

  testWidgets('finish saves instagram handle to updated user', (tester) async {
    final authProvider = FakeAuthProvider(currentUser: createTestUser());
    final matchProvider = FakeMatchProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<MatchProvider>.value(value: matchProvider),
        ],
        child: const MaterialApp(home: ProfileSetupScreen(isEditing: true)),
      ),
    );

    final instagramField = find.bySemanticsLabel('Instagram Handle');

    expect(instagramField, findsOneWidget);

    await tester.enterText(instagramField, '  @summit.alex  ');
    await tester.pumpAndSettle();

    await tester.tap(find.text('NEXT'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('NEXT'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('FINISH'));
    await tester.pumpAndSettle();

    expect(authProvider.currentUser?.instagramHandle, '@summit.alex');
  });
}
