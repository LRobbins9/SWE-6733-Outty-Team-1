import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart' show UserCredential;
import 'package:provider/provider.dart';
import 'package:outty/providers/auth_provider.dart';
import 'package:outty/providers/block_provider.dart';
import 'package:outty/providers/chat_provider.dart';
import 'package:outty/providers/match_provider.dart';
import 'package:outty/providers/navigation_notifier.dart';
import 'package:outty/screens/home_screen.dart';
import 'package:outty/models/user_model.dart';
import 'package:outty/models/match_model.dart';
import 'package:outty/models/block_model.dart';

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
  Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) async {
    return true;
  }

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
  Future<void> deleteProfilePhotosForUser(String uid) async {}

  @override
  Future<void> tryRestoreSession() async {}

  @override
  Future<String?> uploadProfilePhoto() async {
    return null;
  }

  @override
  void clearError() {}

  @override
  Future<void> updateCurrentUser(UserModel updated) async {}
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

  @override
  Future<void> load(UserModel user) async {}

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
  Future<UserModel?> getUserById(String id) async {
    return null;
  }

  @override
  Future<void> updateLastMessage(String matchId, String message) async {}

  @override
  Future<void> resetFeed(UserModel currentUser) async {}

    @override
  BlockProvider get blockProvider {
    throw UnimplementedError();
  }
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

UserModel createTestUser({
  String id = 'test_id',
  String name = 'Test User',
  int age = 30,
  String bio = 'Test bio',
  String email = 'test@example.com',
  List<String>? adventureTypes,
  String skillLevel = 'beginner',
}) {
  return UserModel(
    id: id,
    name: name,
    age: age,
    bio: bio,
    email: email,
    adventureTypes: adventureTypes ?? ['hiking'],
    skillLevel: skillLevel,
  );
}

void main() {
  group('HomeScreen', () {
    late FakeAuthProvider fakeAuthProvider;
    late FakeMatchProvider fakeMatchProvider;
    late FakeNavigationNotifier fakeNavigationNotifier;
    late ChatProvider fakeChatProvider;

    setUp(() {
      fakeAuthProvider = FakeAuthProvider(currentUser: createTestUser());
      fakeMatchProvider = FakeMatchProvider();
      fakeNavigationNotifier = FakeNavigationNotifier();
      fakeChatProvider = ChatProvider(firestore: FakeFirebaseFirestore());
    });

    Widget createWidgetUnderTest() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: fakeAuthProvider),
          ChangeNotifierProvider<MatchProvider>.value(value: fakeMatchProvider),
          ChangeNotifierProvider<ChatProvider>.value(value: fakeChatProvider),
          ChangeNotifierProvider<NavigationNotifier>.value(
            value: fakeNavigationNotifier,
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      );
    }

    testWidgets(
      'HomeScreen renders correctly and shows DiscoverScreen by default',
      (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Discover'), findsWidgets);
        expect(find.text('Matches'), findsWidgets);
        expect(find.text('Profile'), findsWidgets);
      },
    );

    testWidgets('tapping navigation bar switches pages', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Start on Discover
      expect(fakeNavigationNotifier.currentIndex, 0);

      // Tap Matches
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pumpAndSettle();
      expect(fakeNavigationNotifier.currentIndex, 1);

      // Tap Profile
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      expect(fakeNavigationNotifier.currentIndex, 2);
    });

    testWidgets('shows a loading state when auth user becomes null', (
      WidgetTester tester,
    ) async {
      fakeAuthProvider.currentUser = null;
      fakeAuthProvider.notifyListeners();

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
