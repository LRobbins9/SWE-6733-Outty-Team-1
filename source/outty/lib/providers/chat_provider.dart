import 'package:flutter/foundation.dart';
import '../models/message_model.dart';

/// Holds in-memory chat messages per match.
///
/// In a production app this would sync with a backend (e.g. Firebase / WebSocket).
class ChatProvider extends ChangeNotifier {
  final Map<String, List<MessageModel>> _messages = {};
  int _msgCounter = 0;

  List<MessageModel> getMessages(String matchId) =>
      List.unmodifiable(_messages[matchId] ?? []);

  // ── Send ───────────────────────────────────────────────────────────────────

  MessageModel sendMessage({
    required String matchId,
    required String senderId,
    required String content,
  }) {
    final msg = MessageModel(
      id: 'msg_${++_msgCounter}',
      matchId: matchId,
      senderId: senderId,
      content: content.trim(),
    );
    _messages.putIfAbsent(matchId, () => []).add(msg);
    notifyListeners();
    return msg;
  }

  // ── Seed starter message ───────────────────────────────────────────────────

  /// Called when a new match is created to seed the conversation with an
  /// icebreaker from the matched user.
  void seedMatchMessage({
    required String matchId,
    required String fromUserId,
    required String fromUserName,
  }) {
    if (_messages.containsKey(matchId)) return; // already seeded
    final iceBreakerMessages = [
      "Hey! Looks like we're both into the outdoors. What's your next adventure?",
      "Nice to match with a fellow adventurer! Have any trips planned?",
      "Hey there! Ready to find our next trail together? 🏔️",
      "Great match! I'd love to hear about your favorite outdoor spot.",
      "Woah, love your adventure profile! We should plan something epic.",
    ];
    final greeting =
        iceBreakerMessages[_msgCounter % iceBreakerMessages.length];
    sendMessage(matchId: matchId, senderId: fromUserId, content: greeting);
  }

  // ── Mark read ──────────────────────────────────────────────────────────────

  void markRead(String matchId, String currentUserId) {
    final msgs = _messages[matchId];
    if (msgs == null) return;
    for (final m in msgs) {
      if (m.senderId != currentUserId) m.isRead = true;
    }
    notifyListeners();
  }
}
