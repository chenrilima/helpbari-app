class BariaMessage {
  const BariaMessage({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.isFromUser,
  });

  final String id;
  final String content;
  final DateTime timestamp;
  final bool isFromUser;

  BariaMessage copyWith({
    String? id,
    String? content,
    DateTime? timestamp,
    bool? isFromUser,
  }) {
    return BariaMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isFromUser: isFromUser ?? this.isFromUser,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BariaMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          content == other.content &&
          timestamp == other.timestamp &&
          isFromUser == other.isFromUser;

  @override
  int get hashCode =>
      id.hashCode ^ content.hashCode ^ timestamp.hashCode ^ isFromUser.hashCode;
}
