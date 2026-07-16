import 'baria_insight.dart';

class BariaMessage {
  const BariaMessage({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.isFromUser,
    this.action,
  });

  final String id;
  final String content;
  final DateTime timestamp;
  final bool isFromUser;
  final BariaInsightAction? action;

  BariaMessage copyWith({
    String? id,
    String? content,
    DateTime? timestamp,
    bool? isFromUser,
    BariaInsightAction? action,
  }) {
    return BariaMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isFromUser: isFromUser ?? this.isFromUser,
      action: action ?? this.action,
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
