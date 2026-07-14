class MatchModel {
  final String id;
  final String userId1;
  final String userId2;
  final DateTime matchedAt;
  bool hasUnreadMessages;
  String? lastMessage;
  DateTime? lastMessageAt;
  List<String> readBy;

  MatchModel({
    required this.id,
    required this.userId1,
    required this.userId2,
    DateTime? matchedAt,
    this.hasUnreadMessages = false,
    this.lastMessage,
    this.lastMessageAt,
    this.readBy = const [],
  }) : matchedAt = matchedAt ?? DateTime.now();

  String otherUserId(String currentUserId) =>
      userId1 == currentUserId ? userId2 : userId1;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId1': userId1,
        'userId2': userId2,
        'matchedAt': matchedAt.toIso8601String(),
        'hasUnreadMessages': hasUnreadMessages,
        'lastMessage': lastMessage,
        'lastMessageAt': lastMessageAt?.toIso8601String(),
        'readBy': readBy,
      };

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic date) {
      if (date is String) return DateTime.parse(date);
      if (date is DateTime) return date;
      try {
        return (date as dynamic).toDate() as DateTime;
      } catch (_) {
        return DateTime.now();
      }
    }

    return MatchModel(
      id: json['id'] as String,
      userId1: json['userId1'] as String,
      userId2: json['userId2'] as String,
      matchedAt: parseDate(json['matchedAt']),
      hasUnreadMessages: json['hasUnreadMessages'] as bool? ?? false,
      lastMessage: json['lastMessage'] as String?,
      lastMessageAt: json['lastMessageAt'] != null
          ? parseDate(json['lastMessageAt'])
          : null,
      readBy:
          (json['readBy'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
    );
  }
}
