import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outty/models/match_model.dart';
import 'package:outty/models/user_model.dart';
import 'package:outty/providers/auth_provider.dart';
import 'package:outty/providers/chat_provider.dart';
import 'package:outty/providers/match_provider.dart';
import 'package:outty/screens/chat_screen.dart';
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
  void clearError() {}

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
}

void main() {
  testWidgets('ChatScreen can dispose without provider lookup exceptions', (
    tester,
  ) async {
    final fakeFirestore = FakeFirebaseFirestore();
    const matchId = 'match-1';
    await fakeFirestore.collection('matches').doc(matchId).set({
      'id': matchId,
      'userId1': 'user-1',
      'userId2': 'user-2',
      'matchedAt': DateTime.now().toIso8601String(),
      'hasUnreadMessages': true,
    });

    final authProvider = FakeAuthProvider(
      currentUser: UserModel(
        id: 'user-1',
        name: 'Alex',
        age: 28,
        bio: 'Bio',
        email: 'alex@outty.app',
        adventureTypes: const ['Hiking'],
        skillLevel: 'Beginner',
      ),
    );
    final chatProvider = ChatProvider(firestore: fakeFirestore);
    final matchProvider = FakeMatchProvider();
    final match = MatchModel(id: matchId, userId1: 'user-1', userId2: 'user-2');
    final otherUser = UserModel(
      id: 'user-2',
      name: 'Taylor',
      age: 30,
      bio: 'Explorer',
      email: 'taylor@outty.app',
      adventureTypes: const ['Camping'],
      skillLevel: 'Intermediate',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<ChatProvider>.value(value: chatProvider),
          ChangeNotifierProvider<MatchProvider>.value(value: matchProvider),
        ],
        child: MaterialApp(
          home: ChatScreen(match: match, otherUser: otherUser),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
