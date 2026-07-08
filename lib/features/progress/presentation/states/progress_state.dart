import '../../domain/models/models.dart';

class ProgressState {
  const ProgressState({this.summary, this.isLoading = false});

  final ProgressSummary? summary;
  final bool isLoading;

  bool get hasSummary => summary != null;

  ProgressState copyWith({ProgressSummary? summary, bool? isLoading}) {
    return ProgressState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
