import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outty/models/match_model.dart';
import 'package:outty/models/user_model.dart';
import 'package:outty/providers/auth_provider.dart';
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
    },
  );
}
