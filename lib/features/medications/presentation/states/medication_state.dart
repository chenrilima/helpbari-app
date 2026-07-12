import '../../domain/entities/entities.dart';
import '../../domain/value_objects/medication_status.dart';

class MedicationState {
  const MedicationState({
    this.medications = const [],
    this.logs = const [],
    this.isLoading = false,
    this.errorMessage,
    this.syncWarning,
  });
  final List<Medication> medications;
  final List<MedicationLog> logs;
  final bool isLoading;
  final String? errorMessage;
  final String? syncWarning;
  bool get hasMedications => medications.isNotEmpty;
  MedicationStatus statusFor(String id) =>
      logs.where((l) => l.medicationId == id).firstOrNull?.status ??
      MedicationStatus.pending;
  int get pendingCount => medications
      .where((m) => statusFor(m.id) == MedicationStatus.pending)
      .length;
  MedicationState copyWith({
    List<Medication>? medications,
    List<MedicationLog>? logs,
    bool? isLoading,
    String? errorMessage,
    String? syncWarning,
    bool clearError = false,
    bool clearWarning = false,
  }) => MedicationState(
    medications: medications ?? this.medications,
    logs: logs ?? this.logs,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    syncWarning: clearWarning ? null : syncWarning ?? this.syncWarning,
  );
}
