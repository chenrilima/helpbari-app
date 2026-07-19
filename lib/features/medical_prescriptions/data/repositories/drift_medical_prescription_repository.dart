import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/drift_medical_prescription_local_datasource.dart';

class DriftMedicalPrescriptionRepository
    implements MedicalPrescriptionRepository {
  const DriftMedicalPrescriptionRepository(this._local);
  final Future<DriftMedicalPrescriptionLocalDatasource> Function() _local;

  @override
  Stream<List<MedicalPrescription>> watchAll() async* {
    yield* (await _local()).watchAll();
  }

  @override
  Future<List<MedicalPrescription>> getAll() async => (await _local()).getAll();
  @override
  Future<MedicalPrescription?> getById(String id) async =>
      (await _local()).getById(id);
  @override
  Future<void> save(MedicalPrescription prescription) async =>
      (await _local()).save(prescription);
  @override
  Future<void> delete(String id) async => (await _local()).delete(id);
}
