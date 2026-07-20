import '../../../smart_routines/application/unified_treatment_store.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/value_objects/value_objects.dart';

final class UnifiedMedicationRepository implements MedicationRepository {
  const UnifiedMedicationRepository(this.store);
  final UnifiedTreatmentStore store;

  @override
  Future<List<Medication>> getAll() async => [
    for (final value in await store.list(TreatmentSpecialization.medication))
      Medication(
        id: value.id,
        name: MedicationName.create(value.name)!,
        scheduleTime: MedicationScheduleTime.create(
          hour: value.hour,
          minute: value.minute,
        )!,
        dosage: value.dosage,
        notes: value.notes,
      ),
  ];

  @override
  Future<void> save(Medication value) => _save(value);
  @override
  Future<void> update(Medication value) => _save(value);
  Future<void> _save(Medication value) => store.save(
    kind: TreatmentSpecialization.medication,
    value: TreatmentProjection(
      id: value.id,
      name: value.name.value,
      hour: value.scheduleTime.hour,
      minute: value.scheduleTime.minute,
      dosage: value.dosage,
      notes: value.notes,
    ),
  );
  @override
  Future<void> delete(String id) => store.archive(id);
}

final class UnifiedMedicationLogRepository implements MedicationLogRepository {
  const UnifiedMedicationLogRepository(this.store);
  final UnifiedTreatmentStore store;

  @override
  Future<List<MedicationLog>> getByPeriod(DateTime start, DateTime end) async =>
      [
        for (final value in await store.logs(
          TreatmentSpecialization.medication,
          start,
          end,
        ))
          MedicationLog(
            id: value.id,
            medicationId: value.treatmentId,
            date: value.date,
            status: MedicationStatus.values.byName(value.state.name),
          ),
      ];

  @override
  Future<MedicationLog> setStatus({
    required String medicationId,
    required DateTime date,
    required MedicationStatus status,
  }) async {
    final value = await store.setDailyState(
      kind: TreatmentSpecialization.medication,
      treatmentId: medicationId,
      date: date,
      state: TreatmentDailyState.values.byName(status.name),
    );
    return MedicationLog(
      id: value.id,
      medicationId: value.treatmentId,
      date: value.date,
      status: status,
    );
  }

  @override
  Future<void> deleteForMedication(String medicationId) async {}
}
