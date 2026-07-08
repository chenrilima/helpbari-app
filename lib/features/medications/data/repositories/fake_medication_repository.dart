import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

class FakeMedicationRepository implements MedicationRepository {
  final List<Medication> _medications = [];

  @override
  Future<List<Medication>> getAll() async {
    final medications = [..._medications];

    medications.sort((a, b) {
      final hourComparison = a.scheduleTime.hour.compareTo(b.scheduleTime.hour);

      if (hourComparison != 0) {
        return hourComparison;
      }

      return a.scheduleTime.minute.compareTo(b.scheduleTime.minute);
    });

    return List.unmodifiable(medications);
  }

  @override
  Future<void> save(Medication medication) async {
    _medications.add(medication);
  }

  @override
  Future<void> update(Medication medication) async {
    final index = _medications.indexWhere((item) => item.id == medication.id);

    if (index == -1) return;

    _medications[index] = medication;
  }

  @override
  Future<void> delete(String id) async {
    _medications.removeWhere((item) => item.id == id);
  }
}
