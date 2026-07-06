import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

/// syncs chat messages per match with Firestore.
class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _db;

  // Add a constructor to allow injecting a Firestore instance for testing
  ChatProvider({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final Map<String, List<MessageModel>> _messages = {};
  final Map<String, StreamSubscription> _subscriptions = {};

  List<MessageModel> getMessages(String matchId) =>
      List.unmodifiable(_messages[matchId] ?? []);

  // ── Sync ───────────────────────────────────────────────────────────────────

  /// Starts listening to messages for a specific match.
  void listenToMessages(String matchId) {
    if (_subscriptions.containsKey(matchId)) return;

    final sub = _db
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .listen((snapshot) {
      _messages[matchId] = snapshot.docs
          .map((doc) => MessageModel.fromJson(doc.data()))
          .toList();
      notifyListeners();
    });

    _subscriptions[matchId] = sub;
  }

  void stopListening(String matchId) {
    _subscriptions[matchId]?.cancel();
    _subscriptions.remove(matchId);
  }

  @override
  void dispose() {
    for (var sub in _subscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }

  // ── Send ───────────────────────────────────────────────────────────────────

  Future<void> sendMessage({
    required String matchId,
    required String senderId,
    required String content,
  }) async {
    final docRef = _db
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .doc();

    final msg = MessageModel(
      id: docRef.id,
      matchId: matchId,
      senderId: senderId,
      content: content.trim(),
    );

    try {
      await docRef.set(msg.toJson());
      
      // Update last message in match document
      await _db.collection('matches').doc(matchId).update({
        'lastMessage': msg.content,
        'lastMessageAt': msg.sentAt.toIso8601String(),
        'hasUnreadMessages': true,
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  // ── Seed starter message ───────────────────────────────────────────────────

  Future<void> seedMatchMessage({
    required String matchId,
    required String fromUserId,
    required String fromUserName,
  }) async {
    // Check if any messages exist
    final snapshot = await _db
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) return;

    final iceBreakerMessages = [
      "Hey! Looks like we're both into the outdoors. What's your next adventure?",
      "Nice to match with a fellow adventurer! Have any trips planned?",
      "Hey there! Ready to find our next trail together? 🏔️",
      "Great match! I'd love to hear about your favorite outdoor spot.",
      "Woah, love your adventure profile! We should plan something epic.",
    ];
    
    final greeting = iceBreakerMessages[
        matchId.hashCode.abs() % iceBreakerMessages.length];
        
    await sendMessage(
      matchId: matchId,
      senderId: fromUserId,
      content: greeting,
    );
  }

  // ── Mark read ──────────────────────────────────────────────────────────────

  Future<void> markRead(String matchId, String currentUserId) async {
    try {
      // Update hasUnreadMessages on the match document
      await _db.collection('matches').doc(matchId).update({
        'hasUnreadMessages': false,
      });

      final snapshot = await _db
          .collection('matches')
          .doc(matchId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _db.batch();
      for (var doc in snapshot.docs) {
        if (doc.data()['senderId'] != currentUserId) {
          batch.update(doc.reference, {'isRead': true});
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }
}