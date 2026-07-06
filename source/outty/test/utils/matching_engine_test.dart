import 'package:flutter_test/flutter_test.dart';
import 'package:outty/models/user_model.dart';
import 'package:outty/utils/matching_engine.dart';

void main() {
  // Define test users
  final userA = UserModel(
    id: 'a',
    name: 'User A',
    age: 30,
    bio: 'Bio A',
    email: 'a@test.com',
    adventureTypes: ['Hiking', 'Kayaking'],
    skillLevel: 'Intermediate',
    interestedIn: 'Woman',
    targetAgeStart: 25,
    targetAgeEnd: 35,
  );

  final userB = UserModel(
    id: 'b',
    name: 'User B',
    age: 28,
    bio: 'Bio B',
    email: 'b@test.com',
    gender: 'Woman',
    adventureTypes: ['Hiking', 'Kayaking'],
    skillLevel: 'Intermediate',
    targetAgeStart: 28,
    targetAgeEnd: 38,
  );

  final userC = UserModel(
    id: 'c',
    name: 'User C',
    age: 32,
    bio: 'Bio C',
    email: 'c@test.com',
    gender: 'Woman',
    adventureTypes: ['Hiking', 'Skiing'],
    skillLevel: 'Advanced',
  );

  final userdAgeMismatch = UserModel(
    id: 'd',
    name: 'User D',
    age: 40,
    bio: 'Bio D',
    email: 'd@test.com',
    gender: 'Woman',
    adventureTypes: ['Hiking', 'Kayaking'],
    skillLevel: 'Intermediate',
  );

  final usereGenderMismatch = UserModel(
    id: 'e',
    name: 'User E',
    age: 30,
    bio: 'Bio E',
    email: 'e@test.com',
    gender: 'Man',
    adventureTypes: ['Hiking', 'Kayaking'],
    skillLevel: 'Intermediate',
  );

  group('computeCompatibilityScore', () {
    test('returns a perfect score for a perfect match', () {
      final score = computeCompatibilityScore(userA, userB);
      // adventureScore = 1.0, skillScore = 1.0, distanceScore = 1.0
      // 1.0 * 0.5 + 1.0 * 0.3 + 1.0 * 0.2 = 1.0
      expect(score, 1.0);
    });

    test('returns a partial score for a partial match', () {
      final score = computeCompatibilityScore(userA, userC);
      // adventureScore: 1 shared / 3 total = 0.333
      // skillScore: 1 level diff = 0.75
      // distanceScore = 1.0
      // 0.333 * 0.5 + 0.75 * 0.3 + 1.0 * 0.2 = 0.1665 + 0.225 + 0.2 = 0.5915
      expect(score, closeTo(0.59, 0.01));
    });

    test('returns 0.0 for age preference mismatch', () {
      final score = computeCompatibilityScore(userA, userdAgeMismatch);
      expect(score, 0.0);
    });

    test('returns 0.0 for gender preference mismatch', () {
      final score = computeCompatibilityScore(userA, usereGenderMismatch);
      expect(score, 0.0);
    });
  });

  group('rankCandidates', () {
    test('correctly sorts candidates by score', () {
      final candidates = [
        userdAgeMismatch, // score 0
        userC, // score ~0.59
        usereGenderMismatch, // score 0
        userB, // score 1.0
      ];

      final ranked = rankCandidates(userA, candidates);

      expect(ranked.length, 2);
      expect(ranked[0].id, 'b');
      expect(ranked[1].id, 'c');
    });
  });
}