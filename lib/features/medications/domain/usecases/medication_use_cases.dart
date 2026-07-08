import '../entities/entities.dart';
import '../repositories/repositories.dart';
import '../value_objects/value_objects.dart';
import '../models/models.dart';

class MedicationUseCases {
  const MedicationUseCases(this._repository);

  final MedicationRepository _repository;

  Future<List<Medication>> getAll() {
    return _repository.getAll();
  }

  Future<void> save(Medication medication) {
    return _repository.save(medication);
  }

  Future<void> update(Medication medication) {
    return _repository.update(medication);
  }

  Future<void> delete(String id) {
    return _repository.delete(id);
  }

  Future<int> getPendingCount() async {
    final medications = await _repository.getAll();

    return medications.where((medication) => medication.isPending).length;
  }

  Future<MedicationSummary> getSummary() async {
    final medications = await _repository.getAll();

    return MedicationSummary(
      pendingCount: medications.where((item) => item.isPending).length,
      hasMedications: medications.isNotEmpty,
    );
  }

  Future<void> markAsTaken(String id) async {
    final medications = await _repository.getAll();
    final medication = medications.where((item) => item.id == id).firstOrNull;

    if (medication == null) return;

    await _repository.update(medication.markAsTaken());
  }

  Future<void> markAsSkipped(String id) async {
    final medications = await _repository.getAll();
    final medication = medications.where((item) => item.id == id).firstOrNull;

    if (medication == null) return;

    await _repository.update(medication.markAsSkipped());
  }

  Future<void> resetStatus(String id) async {
    final medications = await _repository.getAll();
    final medication = medications.where((item) => item.id == id).firstOrNull;

    if (medication == null) return;

    await _repository.update(
      medication.copyWith(status: MedicationStatus.pending),
    );
  }
}
