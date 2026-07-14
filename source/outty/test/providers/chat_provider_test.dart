// test/providers/chat_provider_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outty/providers/chat_provider.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late ChatProvider chatProvider;

  const matchId = 'test_match_123';
  const userId1 = 'user_1';
  const userId2 = 'user_2';

  setUp(() async {
    // Initialize a new fake firestore instance for each test
    fakeFirestore = FakeFirebaseFirestore();

    // Seed the match document
    await fakeFirestore.collection('matches').doc(matchId).set({
      'participants': [userId1, userId2],
      'createdAt': DateTime.now().toIso8601String(),
    });

    // Create a ChatProvider and inject the fake instance
    chatProvider = ChatProvider(firestore: fakeFirestore);
  });

  group('ChatProvider Tests', () {
    test('sendMessage should add a message and update the match document',
        () async {
      const content = 'Hello, world!';
      await chatProvider.sendMessage(
        matchId: matchId,
        senderId: userId1,
        content: content,
      );

      // Verify message was created
      final messageSnapshot = await fakeFirestore
          .collection('matches')
          .doc(matchId)
          .collection('messages')
          .get();
      expect(messageSnapshot.docs.length, 1);
      expect(messageSnapshot.docs.first['content'], content);

      // Verify match was updated
      final matchSnapshot =
          await fakeFirestore.collection('matches').doc(matchId).get();
      expect(matchSnapshot.data()?['lastMessage'], content);
      expect(matchSnapshot.data()?['readBy'], contains(userId1));
    });

    test('seedMatchMessage should add a greeting if no messages exist',
        () async {
      await chatProvider.seedMatchMessage(
        matchId: matchId,
        fromUserId: userId1,
        fromUserName: 'User 1',
      );

      final finalSnapshot = await fakeFirestore
          .collection('matches')
          .doc(matchId)
          .collection('messages')
          .get();
      expect(finalSnapshot.docs.length, 1);
      expect(finalSnapshot.docs.first.exists, isTrue);
    });

    test('seedMatchMessage should not add a message if one already exists',
        () async {
      // Pre-add a message
      await fakeFirestore
          .collection('matches')
          .doc(matchId)
          .collection('messages')
          .add({'content': 'Existing message'});

      // Attempt to seed
      await chatProvider.seedMatchMessage(
        matchId: matchId,
        fromUserId: userId1,
        fromUserName: 'User 1',
      );

      // Verify no new message was added
      final finalSnapshot = await fakeFirestore
          .collection('matches')
          .doc(matchId)
          .collection('messages')
          .get();
      expect(finalSnapshot.docs.length, 1);
    });

    test('markRead should update readBy and message statuses',
        () async {
      // Set match as unread
      await fakeFirestore
          .collection('matches')
          .doc(matchId)
          .update({'readBy': [userId1]});

      // Add an unread message from the other user
      final messageRef = await fakeFirestore
          .collection('matches')
          .doc(matchId)
          .collection('messages')
          .add({
        'senderId': userId2,
        'isRead': false,
        'content': 'Unread message'
      });

      // Mark as read from user1's perspective
      await chatProvider.markRead(matchId, userId1);

      // Verify match is now marked as read
      final matchDoc =
          await fakeFirestore.collection('matches').doc(matchId).get();
      expect(matchDoc['readBy'], contains(userId1));

      // Verify the message is now marked as read
      final messageDoc = await messageRef.get();
      expect(messageDoc['isRead'], true);
    });
  });
}