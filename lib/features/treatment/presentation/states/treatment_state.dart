import '../../../smart_routines/application/unified_treatment_store.dart';

final class TreatmentState {
  const TreatmentState({
    this.items = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  final List<TreatmentItemSnapshot> items;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  TreatmentState copyWith({
    List<TreatmentItemSnapshot>? items,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) => TreatmentState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    isSaving: isSaving ?? this.isSaving,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}
