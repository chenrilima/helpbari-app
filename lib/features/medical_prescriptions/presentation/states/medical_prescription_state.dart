import '../../domain/entities/entities.dart';

class MedicalPrescriptionState {
  const MedicalPrescriptionState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
  });
  final List<MedicalPrescription> items;
  final bool isLoading;
  final String? errorMessage;

  MedicalPrescriptionState copyWith({
    List<MedicalPrescription>? items,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) => MedicalPrescriptionState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}
