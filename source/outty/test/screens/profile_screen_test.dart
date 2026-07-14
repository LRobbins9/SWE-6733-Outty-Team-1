import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outty/models/match_model.dart';
import 'package:outty/models/user_model.dart';
import 'package:outty/providers/auth_provider.dart';
import 'package:outty/providers/match_provider.dart';
import 'package:outty/screens/profile_screen.dart';
import 'package:outty/widgets/user_avatar.dart';
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

  int uploadPhotoCallCount = 0;

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
    uploadPhotoCallCount += 1;
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
  Widget buildScreen({
    required FakeAuthProvider authProvider,
    FakeMatchProvider? matchProvider,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<MatchProvider>.value(
          value: matchProvider ?? FakeMatchProvider(),
        ),
      ],
      child: const MaterialApp(home: ProfileScreen()),
    );
  }

  testWidgets('ProfileScreen shows loading state when auth user is null', (
    tester,
  ) async {
    final authProvider = FakeAuthProvider(currentUser: null);
    await tester.pumpWidget(buildScreen(authProvider: authProvider));

    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ProfileScreen shows upload photo control for signed-in user', (
    tester,
  ) async {
    final authProvider = FakeAuthProvider(
      currentUser: UserModel(
        id: 'user-1',
        name: 'Alex Hiker',
        age: 28,
        bio: 'Ready for a trail.',
        email: 'alex@example.com',
        adventureTypes: const ['Hiking'],
        skillLevel: 'Beginner',
      ),
    );
    await tester.pumpWidget(buildScreen(authProvider: authProvider));

    await tester.pumpAndSettle();

    expect(find.text('Upload Photo'), findsOneWidget);
    expect(find.text('One compressed profile photo'), findsOneWidget);
  });

  testWidgets(
    'ProfileScreen disables upload button while upload is in progress',
    (tester) async {
      final authProvider = FakeAuthProvider(
        currentUser: UserModel(
          id: 'user-1',
          name: 'Alex Hiker',
          age: 28,
          bio: 'Ready for a trail.',
          email: 'alex@example.com',
          adventureTypes: const ['Hiking'],
          skillLevel: 'Beginner',
        ),
      )..isLoading = true;

      await tester.pumpWidget(buildScreen(authProvider: authProvider));
      await tester.pump();

      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));

      expect(button.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );

  testWidgets('ProfileScreen taps upload button through auth provider', (
    tester,
  ) async {
    final authProvider = FakeAuthProvider(
      currentUser: UserModel(
        id: 'user-1',
        name: 'Alex Hiker',
        age: 28,
        bio: 'Ready for a trail.',
        email: 'alex@example.com',
        adventureTypes: const ['Hiking'],
        skillLevel: 'Beginner',
      ),
    );

    await tester.pumpWidget(buildScreen(authProvider: authProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Upload Photo'));
    await tester.pump();

    expect(authProvider.uploadPhotoCallCount, 1);
  });

  testWidgets('ProfileScreen renders helper text below upload button', (
    tester,
  ) async {
    final authProvider = FakeAuthProvider(
      currentUser: UserModel(
        id: 'user-1',
        name: 'Alex Hiker',
        age: 28,
        bio: 'Ready for a trail.',
        email: 'alex@example.com',
        adventureTypes: const ['Hiking'],
        skillLevel: 'Beginner',
      ),
    );

    await tester.pumpWidget(buildScreen(authProvider: authProvider));
    await tester.pumpAndSettle();

    final uploadButton = find.text('Upload Photo');
    final helperText = find.text('One compressed profile photo');

    expect(uploadButton, findsOneWidget);
    expect(helperText, findsOneWidget);
    expect(
      tester.getTopLeft(helperText).dy,
      greaterThan(tester.getBottomLeft(uploadButton).dy),
    );
  });

  testWidgets('ProfileScreen shows user avatar widget for signed-in user', (
    tester,
  ) async {
    final authProvider = FakeAuthProvider(
      currentUser: UserModel(
        id: 'user-1',
        name: 'Alex Hiker',
        age: 28,
        bio: 'Ready for a trail.',
        email: 'alex@example.com',
        adventureTypes: const ['Hiking'],
        skillLevel: 'Beginner',
        photoUrl: 'https://example.com/profile.png',
      ),
    );

    await tester.pumpWidget(buildScreen(authProvider: authProvider));
    await tester.pumpAndSettle();

    expect(find.byType(UserAvatar), findsOneWidget);
  });
}
