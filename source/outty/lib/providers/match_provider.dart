import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/match_model.dart';
import '../models/user_model.dart';
import '../utils/matching_engine.dart';
import '../utils/mock_data.dart';

/// Manages the discovery feed, swipe actions, and matches.
class MatchProvider extends ChangeNotifier {
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
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    // Restore swiped ids
    final swipedRaw = prefs.getStringList('swiped_${currentUser.id}') ?? [];
    _swipedIds
      ..clear()
      ..addAll(swipedRaw);

    // Restore matches
    _matches.clear();
    final matchesRaw =
        prefs.getStringList('matches_${currentUser.id}') ?? [];
    for (final raw in matchesRaw) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        _matches.add(MatchModel(
          id: m['id'] as String,
          userId1: m['userId1'] as String,
          userId2: m['userId2'] as String,
          matchedAt: DateTime.parse(m['matchedAt'] as String),
          lastMessage: m['lastMessage'] as String?,
          lastMessageAt: m['lastMessageAt'] != null
              ? DateTime.parse(m['lastMessageAt'] as String)
              : null,
        ));
      } catch (_) {}
    }

    // Build ranked feed (exclude already swiped and already matched)
    final matchedIds = _matches
        .map((m) => m.otherUserId(currentUser.id))
        .toSet();
    final candidates = kMockUsers
        .where((u) =>
            u.id != currentUser.id &&
            !_swipedIds.contains(u.id) &&
            !matchedIds.contains(u.id))
        .toList();

    _feed = rankCandidates(currentUser, candidates);

    _isLoading = false;
    notifyListeners();
  }

  // ── Swipe ──────────────────────────────────────────────────────────────────

  /// Returns the newly created [MatchModel] if a match occurred, else null.
  Future<MatchModel?> swipeRight(
      UserModel currentUser, UserModel candidate) async {
    await _recordSwipe(currentUser.id, candidate.id);

<<<<<<< HEAD
    // Simulated: ~60% chance the other user "already liked" you
=======
    // Simulated: ~60 % chance the other user "already liked" you
>>>>>>> 9746a2b (feat: implement Outty MVP adventure-matching Flutter app)
    final score = computeCompatibilityScore(currentUser, candidate);
    final isMatch = score > 0.3; // threshold for MVP

    if (isMatch) {
      final match = MatchModel(
        id: 'match_${currentUser.id}_${candidate.id}',
        userId1: currentUser.id,
        userId2: candidate.id,
      );
      _matches.insert(0, match);
      await _persistMatches(currentUser.id);
      notifyListeners();
      return match;
    }
    return null;
  }

  Future<void> swipeLeft(String currentUserId, String candidateId) async {
    await _recordSwipe(currentUserId, candidateId);
  }

  // ── Match helpers ──────────────────────────────────────────────────────────

  UserModel? getUserById(String id) {
    try {
      return kMockUsers.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  void updateLastMessage(String matchId, String message) {
    final idx = _matches.indexWhere((m) => m.id == matchId);
    if (idx >= 0) {
      _matches[idx].lastMessage = message;
      _matches[idx].lastMessageAt = DateTime.now();
      notifyListeners();
    }
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  Future<void> _recordSwipe(String userId, String candidateId) async {
    _swipedIds.add(candidateId);
    _feed.removeWhere((u) => u.id == candidateId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('swiped_$userId', _swipedIds.toList());
    notifyListeners();
  }

  Future<void> _persistMatches(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _matches.map((m) {
      return jsonEncode({
        'id': m.id,
        'userId1': m.userId1,
        'userId2': m.userId2,
        'matchedAt': m.matchedAt.toIso8601String(),
        'lastMessage': m.lastMessage,
        'lastMessageAt': m.lastMessageAt?.toIso8601String(),
      });
    }).toList();
    await prefs.setStringList('matches_$userId', encoded);
  }

  /// Resets all swipe history (useful for demo / testing).
  Future<void> resetFeed(UserModel currentUser) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('swiped_${currentUser.id}');
    await load(currentUser);
  }
}
