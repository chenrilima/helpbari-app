import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/local_medication_datasource.dart';
import '../dtos/medication_dto.dart';

class LocalMedicationRepository implements MedicationRepository {
  const LocalMedicationRepository(this._datasource);

  final LocalMedicationDatasource _datasource;

  @override
  Future<List<Medication>> getAll() async {
    final medications = await _datasource.getAll();

    return medications.map((medication) => medication.toEntity()).toList();
  }

  @override
  Future<void> save(Medication medication) {
    return _datasource.save(
      MedicationDto.fromEntity(medication, now: DateTime.now()),
    );
  }

  @override
  Future<void> update(Medication medication) {
    return _datasource.save(
      MedicationDto.fromEntity(medication, now: DateTime.now()),
    );
  }

  @override
  Future<void> delete(String id) {
    return _datasource.delete(id);
  }
}
