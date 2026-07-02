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

  Map<String, dynamic> toJson() => {
        'id': id,
        'matchId': matchId,
        'senderId': senderId,
        'content': content,
        'sentAt': sentAt.toIso8601String(),
        'isRead': isRead,
      };

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic date) {
      if (date is String) return DateTime.parse(date);
      if (date is DateTime) return date;
      try {
        return (date as dynamic).toDate() as DateTime;
      } catch (_) {
        return DateTime.now();
      }
    }

    return MessageModel(
      id: json['id'] as String,
      matchId: json['matchId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      sentAt: parseDate(json['sentAt']),
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}
