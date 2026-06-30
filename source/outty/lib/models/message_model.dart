class MessageModel {
  final String id;
  final String matchId;
  final String senderId;
  final String content;
  final DateTime sentAt;
  bool isRead;

  MessageModel({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.content,
    DateTime? sentAt,
    this.isRead = false,
  }) : sentAt = sentAt ?? DateTime.now();
}
