class MatchModel {
  final String id;
  final String userId1;
  final String userId2;
  final DateTime matchedAt;
  bool hasUnreadMessages;
  String? lastMessage;
  DateTime? lastMessageAt;

  MatchModel({
    required this.id,
    required this.userId1,
    required this.userId2,
    DateTime? matchedAt,
    this.hasUnreadMessages = false,
    this.lastMessage,
    this.lastMessageAt,
  }) : matchedAt = matchedAt ?? DateTime.now();

  String otherUserId(String currentUserId) =>
      userId1 == currentUserId ? userId2 : userId1;
}
