import '../entities/entities.dart';

abstract interface class MedicalPrescriptionRepository {
  Stream<List<MedicalPrescription>> watchAll();
  Future<List<MedicalPrescription>> getAll();
  Future<MedicalPrescription?> getById(String id);
  Future<void> save(MedicalPrescription prescription);
  Future<void> delete(String id);
}

abstract interface class MedicalPrescriptionProjectionRepository {
  Future<int> countRequiringReview();
  Future<List<MedicalPrescription>> getLimited({required int limit});
}
