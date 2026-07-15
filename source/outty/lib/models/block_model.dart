class BlockModel {
  final String id;
  final String blockerUserId;
  final String blockedUserId;
  final DateTime blockedAt;

  BlockModel({
    required this.id, 
    required this.blockerUserId, 
    required this.blockedUserId,
    DateTime? blockedAt,
  }) : blockedAt = blockedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'blockerUserId': blockerUserId,
    'blockedUserId': blockedUserId,
    'blockedAt': blockedAt.toIso8601String(),
  };

  factory BlockModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic date) {
      if (date is String) return DateTime.parse(date);
      if (date is DateTime) return date;
      try {
        return (date as dynamic).toDate() as DateTime;
      } catch (_) {
        return DateTime.now();
      }
    }

    return BlockModel(
      id: json['id'] as String,
      blockerUserId: json['blockerUserId'] as String,
      blockedUserId: json['blockedUserId'] as String,
      blockedAt: parseDate(json['blockedAt']),
    );
  }
}