import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart' show UserCredential;
import 'package:outty/models/match_model.dart';
import 'package:outty/models/user_model.dart';
import 'package:outty/models/block_model.dart';
import 'package:outty/providers/auth_provider.dart';
import 'package:outty/providers/block_provider.dart';
import 'package:outty/providers/match_provider.dart';
import 'package:outty/screens/matches_screen.dart';
import 'package:provider/provider.dart';

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  UserModel? currentUser;

  @override
  bool isLoggedIn = false;

  @override
  bool isLoading = false;

  @override
  String? errorMessage;

  FakeAuthProvider({this.currentUser});

  @override
  void clearError() {}

  @override
  Future<bool> login({required String email, required String password}) async {
    return true;
  }

  @override
  Future<void> logout() async {}

  @override
  Future<UserCredential> signInWithGoogle() async {
    throw UnimplementedError();
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
}

class FakeMatchProvider extends ChangeNotifier implements MatchProvider {
  @override
  List<BlockModel> blocks = [];

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

  // Add this map to store users for lookup
  final Map<String, UserModel> _users = {};

  @override
  Future<UserModel?> getUserById(String id) async {
    return _users[id];
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
    BlockProvider get blockProvider {
      throw UnimplementedError();
  }
}

void main() {
  testWidgets(
    'MatchesScreen shows a loading state when the user is not restored yet',
    (tester) async {
      final authProvider = FakeAuthProvider(currentUser: null)
        ..isLoading = true;
      final matchProvider = FakeMatchProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<MatchProvider>.value(value: matchProvider),
          ],
          child: const MaterialApp(home: MatchesScreen()),
        ),
      );

      await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('MatchesScreen shows filtered matches based on search input', (tester) async {
    final authProvider = FakeAuthProvider(
      currentUser: UserModel(
        id: '1',
        name: 'Test User',
        age: 25,
        bio: 'This is a test bio',
        adventureTypes: ['Hiking', 'Camping'],
        skillLevel: 'Intermediate',
        email: 'test@example.com',
      ),
    );
    final matchProvider = FakeMatchProvider();
    final fakeMatch1 = UserModel(
          id: '2',
          name: 'Ivana Partner',
          age: 28,
          bio: 'This is Ivana\'s bio',
          adventureTypes: ['Hiking', 'Camping'],
          skillLevel: 'Advanced',
          email: 'ivana@example.com',
        );
    final fakeMatch2 = UserModel(
          id: '3',
          name: 'Another Partner',
          age: 30,
          bio: 'This is another partner\'s bio',
          adventureTypes: ['Skiing', 'Kayaking'],
          skillLevel: 'Advanced',
          email: 'another@example.com',
        );
    matchProvider._users['2'] = fakeMatch1;
    matchProvider._users['3'] = fakeMatch2;

    matchProvider.matches = [
      MatchModel(
        id: '2_1',
        userId1: authProvider.currentUser!.id,
        userId2: fakeMatch1.id,
        lastMessage: 'Hello!',
      ),
      MatchModel(
        id: '3_1',
        userId1: authProvider.currentUser!.id,
        userId2: fakeMatch2.id,
        lastMessage: 'Hi there!',
      ),
    ];

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<MatchProvider>.value(value: matchProvider),
        ],
        child: const MaterialApp(home: MatchesScreen()),
      ),
    );

    await tester.pumpAndSettle();

    //When the user provides a search filter, the results should react accordingly
    await tester.enterText(find.byType(TextField), 'Ivana');
    await tester.pumpAndSettle();

    // After searching for "Ivana"
    expect(find.text('Ivana Partner, 28'), findsOneWidget);  // In Messages section
    expect(find.text('Another Partner'), findsNothing);  // Filtered out
  });
}
