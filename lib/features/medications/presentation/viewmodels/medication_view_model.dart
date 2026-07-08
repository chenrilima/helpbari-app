import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/entities.dart';
import '../../domain/usecases/use_cases.dart';
import '../../domain/value_objects/value_objects.dart';
import '../providers/medication_use_cases_provider.dart';
import '../states/medication_state.dart';

class MedicationViewModel extends Notifier<MedicationState> {
  final _uuid = const Uuid();

  late final MedicationUseCases _useCases;

  @override
  MedicationState build() {
    _useCases = ref.read(medicationUseCasesProvider);

    return const MedicationState();
  }

  Future<void> loadMedications() async {
    state = state.copyWith(isLoading: true);

    final medications = await _useCases.getAll();

    state = state.copyWith(medications: medications, isLoading: false);
  }

  Future<void> createMedication({
    required String name,
    required int hour,
    required int minute,
    String? dosage,
    String? notes,
  }) async {
    final medicationName = MedicationName.create(name);
    final scheduleTime = MedicationScheduleTime.create(
      hour: hour,
      minute: minute,
    );

    if (medicationName == null || scheduleTime == null) {
      return;
    }

    final medication = Medication(
      id: _uuid.v4(),
      name: medicationName,
      scheduleTime: scheduleTime,
      dosage: dosage,
      notes: notes,
    );

    await _useCases.save(medication);
    await loadMedications();
  }

  Future<void> markAsTaken(String id) async {
    await _useCases.markAsTaken(id);
    await loadMedications();
  }

  Future<void> markAsSkipped(String id) async {
    await _useCases.markAsSkipped(id);
    await loadMedications();
  }

  Future<void> resetStatus(String id) async {
    await _useCases.resetStatus(id);
    await loadMedications();
  }
}
