import '../../domain/models/models.dart';

class BariaState {
  const BariaState({
    this.dailyInsight,
    this.conversationMessages = const [],
    this.isLoading = false,
    this.error,
  });

  final BariaInsight? dailyInsight;
  final List<BariaMessage> conversationMessages;
  final bool isLoading;
  final String? error;

  BariaState copyWith({
    BariaInsight? dailyInsight,
    List<BariaMessage>? conversationMessages,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return BariaState(
      dailyInsight: dailyInsight ?? this.dailyInsight,
      conversationMessages: conversationMessages ?? this.conversationMessages,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BariaState &&
          runtimeType == other.runtimeType &&
          dailyInsight == other.dailyInsight &&
          conversationMessages == other.conversationMessages &&
          isLoading == other.isLoading &&
          error == other.error;

  @override
  int get hashCode =>
      dailyInsight.hashCode ^
      conversationMessages.hashCode ^
      isLoading.hashCode ^
      error.hashCode;
}
