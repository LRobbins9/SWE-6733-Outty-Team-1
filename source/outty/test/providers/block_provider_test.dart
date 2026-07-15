// test/providers/block_provider_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outty/providers/block_provider.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late BlockProvider blockProvider;

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

    // Initialize the block provider with the fake firestore instance
    blockProvider = BlockProvider(firestore: fakeFirestore);
  });

  group('BlockProvider Tests', () {
    test('initially has no blocked users', () async {
      expect(await blockProvider.getBlocks(userId1), isEmpty);
    });

    test('can block a user', () async {
      await blockProvider.blockUser(userId1, userId2, matchId);
      final blocks = await blockProvider.getBlocks(userId1);
      expect(blocks.any((block) => block.blockedUserId == userId2), isTrue);
    });
    
  });


}