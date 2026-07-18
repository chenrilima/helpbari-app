import '../../domain/entities/entities.dart';

class MedicalExamState {
  const MedicalExamState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selected,
  });

  final List<MedicalExam> items;
  final bool isLoading;
  final String? errorMessage;
  final MedicalExam? selected;

  bool get hasItems => items.isNotEmpty;
  MedicalExam? get latestExam => hasItems ? items.first : null;

  MedicalExamState copyWith({
    List<MedicalExam>? items,
    bool? isLoading,
    String? errorMessage,
    MedicalExam? selected,
    bool clearError = false,
    bool clearSelected = false,
  }) => MedicalExamState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    selected: clearSelected ? null : selected ?? this.selected,
  );
}
