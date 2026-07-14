import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:outty/models/match_model.dart';
import 'package:outty/models/message_model.dart';
import 'package:outty/models/user_model.dart';
import 'package:outty/providers/auth_provider.dart';
import 'package:outty/providers/chat_provider.dart';
import 'package:outty/providers/match_provider.dart';
import 'package:outty/screens/chat_screen.dart';
import 'package:outty/widgets/message_bubble.dart';
import 'package:provider/provider.dart';

import 'chat_screen_interaction_test.mocks.dart';

@GenerateMocks([AuthProvider, ChatProvider, MatchProvider])
void main() {
  late MockAuthProvider mockAuthProvider;
  late MockChatProvider mockChatProvider;
  late MockMatchProvider mockMatchProvider;
  late UserModel currentUser;
  late UserModel otherUser;
  late MatchModel match;

  setUp(() {
    mockAuthProvider = MockAuthProvider();
    mockChatProvider = MockChatProvider();
    mockMatchProvider = MockMatchProvider();

    currentUser = UserModel(
      id: 'user-1',
      name: 'Current User',
      age: 28,
      bio: 'Bio',
      email: 'current@outty.app',
      adventureTypes: const ['Hiking'],
      skillLevel: 'Beginner',
    );

    otherUser = UserModel(
      id: 'user-2',
      name: 'Other User',
      age: 30,
      bio: 'Explorer',
      email: 'other@outty.app',
      adventureTypes: const ['Camping'],
      skillLevel: 'Intermediate',
    );

    match = MatchModel(id: 'match-1', userId1: 'user-1', userId2: 'user-2');

    // Stubbing provider methods
    when(mockAuthProvider.currentUser).thenReturn(currentUser);
    when(mockChatProvider.getMessages(any)).thenReturn([]);
    when(mockChatProvider.listenToMessages(any)).thenAnswer((_) async {});
    when(mockChatProvider.markRead(any, any)).thenAnswer((_) async {});
    when(mockChatProvider.seedMatchMessage(
      matchId: anyNamed('matchId'),
      fromUserId: anyNamed('fromUserId'),
      fromUserName: anyNamed('fromUserName'),
    )).thenAnswer((_) async {});
    when(mockMatchProvider.markAsRead(match.id, currentUser.id)).thenAnswer((_) async {});
  });

  Widget createChatScreen({required MatchModel match}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
        ChangeNotifierProvider<ChatProvider>.value(value: mockChatProvider),
        ChangeNotifierProvider<MatchProvider>.value(value: mockMatchProvider),
      ],
      child: MaterialApp(
        home: ChatScreen(match: match, otherUser: otherUser),
      ),
    );
  }

  testWidgets('sending a message calls provider and clears input',
      (WidgetTester tester) async {
    when(mockChatProvider.sendMessage(
      matchId: anyNamed('matchId'),
      senderId: anyNamed('senderId'),
      content: anyNamed('content'),
    )).thenAnswer((_) async => true);

    await tester.pumpWidget(createChatScreen(match: match));

    // Verify initial state
    expect(find.text('Message Other User...'), findsOneWidget);

    // Enter text and send
    await tester.enterText(find.byType(TextField), 'Hello there!');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    // Verify that sendMessage was called
    verify(mockChatProvider.sendMessage(
      matchId: 'match-1',
      senderId: 'user-1',
      content: 'Hello there!',
    )).called(1);

    // Verify the text field is cleared
    expect(find.text('Hello there!'), findsNothing);
  });

  testWidgets('app bar shows other user name and info',
      (WidgetTester tester) async {
    await tester.pumpWidget(createChatScreen(match: match));

    expect(find.text('Other User'), findsOneWidget);
    expect(find.text('Intermediate'), findsOneWidget);
  });

  testWidgets('shows empty state message when there are no messages',
      (WidgetTester tester) async {
    when(mockChatProvider.getMessages(any)).thenReturn([]);

    await tester.pumpWidget(createChatScreen(match: match));
    await tester.pump(); // Let the widget tree build

    expect(find.text('Say hello to Other User!'), findsOneWidget);
  });

  testWidgets('displays messages from chat provider',
      (WidgetTester tester) async {
    final messages = [
      MessageModel(
        id: 'msg-1',
        matchId: 'match-1',
        senderId: 'user-1',
        content: 'Hi!',
        sentAt: DateTime.now(),
      ),
      MessageModel(
        id: 'msg-2',
        matchId: 'match-1',
        senderId: 'user-2',
        content: 'Hello!',
        sentAt: DateTime.now(),
      ),
    ];

    when(mockChatProvider.getMessages(any)).thenReturn(messages);

    await tester.pumpWidget(createChatScreen(match: match));
    await tester.pump();

    expect(find.byType(MessageBubble), findsNWidgets(2));
    expect(find.text('Hi!'), findsOneWidget);
    expect(find.text('Hello!'), findsOneWidget);
  });

  testWidgets('marks match as read for current user',
      (WidgetTester tester) async {
    final unreadMatch = MatchModel(
      id: 'match-1',
      userId1: 'user-1',
      userId2: 'user-2',
      readBy: [], // No one has read it
    );

    await tester.pumpWidget(createChatScreen(match: unreadMatch));

    // Verify that markAsRead was called for the current user
    verify(mockMatchProvider.markAsRead('match-1', 'user-1')).called(1);
  });


  testWidgets('tapping info icon shows profile preview sheet',
      (WidgetTester tester) async {
    await tester.pumpWidget(createChatScreen(match: match));

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();

    expect(find.text('${otherUser.name}, ${otherUser.age}'), findsOneWidget);
    expect(find.text(otherUser.bio), findsOneWidget);
    expect(find.text(otherUser.adventureTypes.first), findsOneWidget);
  });
}
