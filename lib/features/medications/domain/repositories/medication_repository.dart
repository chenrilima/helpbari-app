import '../entities/entities.dart';

abstract interface class MedicationRepository {
  Future<List<Medication>> getAll();

  Future<void> save(Medication medication);

  Future<void> update(Medication medication);

  Future<void> delete(String id);
}
