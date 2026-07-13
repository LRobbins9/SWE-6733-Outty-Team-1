import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outty/models/match_model.dart';
import 'package:outty/models/user_model.dart';
import 'package:outty/providers/auth_provider.dart';
import 'package:outty/providers/match_provider.dart';
import 'package:outty/providers/navigation_notifier.dart';
import 'package:outty/screens/discover_screen.dart';
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
  Future<void> swipeLeft(String currentUserId, String candidateId) async {
    feed.removeWhere((candidate) => candidate.id == candidateId);
    notifyListeners();
  }

  @override
  Future<MatchModel?> swipeRight(
    UserModel currentUser,
    UserModel candidate,
  ) async {
    feed.removeWhere((item) => item.id == candidate.id);
    notifyListeners();
    return MatchModel(
      id: 'match-1',
      userId1: currentUser.id,
      userId2: candidate.id,
    );
  }

  @override
  Future<void> updateLastMessage(String matchId, String message) async {}
}

class FakeNavigationNotifier extends ChangeNotifier
    implements NavigationNotifier {
  @override
  int currentIndex = 0;

  @override
  void switchToIndex(int index) {
    currentIndex = index;
    notifyListeners();
  }

  @override
  void switchToMatches() {
    switchToIndex(1);
  }
}

void main() {
  testWidgets(
    'DiscoverScreen handles empty candidate names and blank avatars',
    (tester) async {
      final authProvider = FakeAuthProvider(
        currentUser: UserModel(
          id: 'current-user',
          name: 'Current User',
          age: 29,
          bio: 'Bio',
          email: 'current@outty.app',
          adventureTypes: ['Hiking'],
          skillLevel: 'Beginner',
          photoUrl: '',
        ),
      );
      final matchProvider = FakeMatchProvider()
        ..feed = [
          UserModel(
            id: 'candidate-1',
            name: '   ',
            age: 30,
            bio: 'Ready to explore.',
            email: 'candidate@outty.app',
            adventureTypes: ['Camping'],
            skillLevel: 'Intermediate',
            photoUrl: '',
          ),
        ];
      final navigationNotifier = FakeNavigationNotifier();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<MatchProvider>.value(value: matchProvider),
            ChangeNotifierProvider<NavigationNotifier>.value(
              value: navigationNotifier,
            ),
          ],
          child: const MaterialApp(home: DiscoverScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Adventurer, 30'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text("It's a Match!"), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
