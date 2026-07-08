import '../../domain/entities/entities.dart';

class MedicationState {
  const MedicationState({this.medications = const [], this.isLoading = false});

  final List<Medication> medications;
  final bool isLoading;

  bool get hasMedications => medications.isNotEmpty;

  int get pendingCount {
    return medications.where((medication) => medication.isPending).length;
  }

  MedicationState copyWith({List<Medication>? medications, bool? isLoading}) {
    return MedicationState(
      medications: medications ?? this.medications,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
