class BariaInsight {
  const BariaInsight({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.healthScoreImprovement,
  });

  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final double? healthScoreImprovement;

  BariaInsight copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? createdAt,
    double? healthScoreImprovement,
  }) {
    return BariaInsight(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      healthScoreImprovement:
          healthScoreImprovement ?? this.healthScoreImprovement,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BariaInsight &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          message == other.message &&
          createdAt == other.createdAt &&
          healthScoreImprovement == other.healthScoreImprovement;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      message.hashCode ^
      createdAt.hashCode ^
      healthScoreImprovement.hashCode;
}
