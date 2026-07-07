import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match_model.dart';
import '../models/user_model.dart';
import '../utils/matching_engine.dart';

/// Manages the discovery feed, swipe actions, and matches using Firestore.
class MatchProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<MatchModel> _matches = [];
  final Set<String> _swipedIds = {};
  List<UserModel> _feed = [];
  bool _isLoading = false;

  List<MatchModel> get matches => List.unmodifiable(_matches);
  List<UserModel> get feed => List.unmodifiable(_feed);
  bool get isLoading => _isLoading;
  bool get feedExhausted => _feed.isEmpty;

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> load(UserModel currentUser) async {
    _isLoading = true;
    Future.microtask(() => notifyListeners());

    try {
      // 1. Restore swiped ids from Firestore
      final swipeDocs = await _db
          .collection('users')
          .doc(currentUser.id)
          .collection('swipes')
          .get();
      
      _swipedIds.clear();
      for (var doc in swipeDocs.docs) {
        _swipedIds.add(doc.id);
      }

      // 2. Restore matches from Firestore
      // We query matches where the current user is either userId1 or userId2
      final matchesQuery1 = await _db
          .collection('matches')
          .where('userId1', isEqualTo: currentUser.id)
          .get();
      final matchesQuery2 = await _db
          .collection('matches')
          .where('userId2', isEqualTo: currentUser.id)
          .get();

      _matches.clear();
      final allMatchDocs = [...matchesQuery1.docs, ...matchesQuery2.docs];
      
      for (var doc in allMatchDocs) {
        _matches.add(MatchModel.fromJson(doc.data()));
      }
      _matches.sort((a, b) => b.matchedAt.compareTo(a.matchedAt));

      // 3. Build ranked feed from Firestore
      // For MVP, we fetch all users and filter locally. 
      // In production, use geo-queries and more complex Firestore filters.
      final usersSnapshot = await _db.collection('users').get();
      final matchedIds = _matches.map((m) => m.otherUserId(currentUser.id)).toSet();
      
      final candidates = usersSnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .where((u) =>
              u.id != currentUser.id &&
              !_swipedIds.contains(u.id) &&
              !matchedIds.contains(u.id))
          .toList();

      _feed = rankCandidates(currentUser, candidates);
    } catch (e) {
      debugPrint('Error loading matches/feed: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Swipe ──────────────────────────────────────────────────────────────────

  /// Returns the newly created [MatchModel] if a match occurred, else null.
  Future<MatchModel?> swipeRight(
      UserModel currentUser, UserModel candidate) async {
    // Optimistic UI update: advance the feed immediately and sync to Firestore after.
    _swipedIds.add(candidate.id);
    _feed.removeWhere((u) => u.id == candidate.id);
    notifyListeners();

    try {
      // 1. Record the swipe in Firestore
      await _db
          .collection('users')
          .doc(currentUser.id)
          .collection('swipes')
          .doc(candidate.id)
          .set({'type': 'right', 'at': FieldValue.serverTimestamp()});

      // 2. Check if the other user already swiped right on us (a match!)
      final otherSwipe = await _db
          .collection('users')
          .doc(candidate.id)
          .collection('swipes')
          .doc(currentUser.id)
          .get();

      if (otherSwipe.exists && otherSwipe.data()?['type'] == 'right') {
        // It's a match!
        final matchId = currentUser.id.hashCode <= candidate.id.hashCode
            ? '${currentUser.id}_${candidate.id}'
            : '${candidate.id}_${currentUser.id}';
        
        final match = MatchModel(
          id: matchId,
          userId1: currentUser.id,
          userId2: candidate.id,
        );

        await _db.collection('matches').doc(matchId).set(match.toJson());
        
        _matches.insert(0, match);
        notifyListeners();
        return match;
      }
    } catch (e) {
      debugPrint('Error during swipeRight: $e');
    }

    return null;
  }

  Future<void> swipeLeft(String currentUserId, String candidateId) async {
    // Optimistic UI update: remove card first, persist swipe after.
    _swipedIds.add(candidateId);
    _feed.removeWhere((u) => u.id == candidateId);
    notifyListeners();

    try {
      await _db
          .collection('users')
          .doc(currentUserId)
          .collection('swipes')
          .doc(candidateId)
          .set({'type': 'left', 'at': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('Error during swipeLeft: $e');
    }
  }

  // ── Match helpers ──────────────────────────────────────────────────────────

  /// Fetches a user profile by ID. Currently checks locally Loaded feed first,
  /// then falls back to Firestore if needed.
  Future<UserModel?> getUserById(String id) async {
    // Check feed first
    for (final u in _feed) {
      if (u.id == id) return u;
    }
    
    // Check matches or Firestore
    try {
      final doc = await _db.collection('users').doc(id).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
    } catch (e) {
      debugPrint('Error fetching user by id: $e');
    }
    return null;
  }

  Future<void> updateLastMessage(String matchId, String message) async {
    final idx = _matches.indexWhere((m) => m.id == matchId);
    if (idx >= 0) {
      final now = DateTime.now();
      _matches[idx].lastMessage = message;
      _matches[idx].lastMessageAt = now;
      
      try {
        await _db.collection('matches').doc(matchId).update({
          'lastMessage': message,
          'lastMessageAt': now.toIso8601String(),
        });
      } catch (e) {
        debugPrint('Error updating last message: $e');
      }
      
      notifyListeners();
    }
  }

  /// Resets all swipe history (useful for demo / testing).
  Future<void> resetFeed(UserModel currentUser) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final swipes = await _db.collection('users').doc(currentUser.id).collection('swipes').get();
      final batch = _db.batch();
      for (var doc in swipes.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      await load(currentUser);
    } catch (e) {
      debugPrint('Error resetting feed: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
}
