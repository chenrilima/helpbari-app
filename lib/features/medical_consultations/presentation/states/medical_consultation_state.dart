import '../../domain/entities/entities.dart';

class MedicalConsultationState {
  const MedicalConsultationState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selected,
  });

  final List<MedicalConsultation> items;
  final bool isLoading;
  final String? errorMessage;
  final MedicalConsultation? selected;

  bool get hasItems => items.isNotEmpty;
  MedicalConsultation? get latestConsultation => hasItems ? items.first : null;

  MedicalConsultationState copyWith({
    List<MedicalConsultation>? items,
    bool? isLoading,
    String? errorMessage,
    MedicalConsultation? selected,
    bool clearError = false,
    bool clearSelected = false,
  }) => MedicalConsultationState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    selected: clearSelected ? null : selected ?? this.selected,
  );
}
