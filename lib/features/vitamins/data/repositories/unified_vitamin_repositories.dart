import '../../../smart_routines/application/unified_treatment_store.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/value_objects/value_objects.dart';

final class UnifiedVitaminRepository implements VitaminRepository {
  const UnifiedVitaminRepository(this.store);
  final UnifiedTreatmentStore store;

  @override
  Future<List<Vitamin>> getAll() async => [
    for (final value in await store.list(TreatmentSpecialization.vitamin))
      Vitamin(
        id: value.id,
        name: VitaminName.create(value.name)!,
        scheduleTime: VitaminScheduleTime.create(
          hour: value.hour,
          minute: value.minute,
        )!,
      ),
  ];

  @override
  Future<void> save(Vitamin value) => _save(value);
  @override
  Future<void> update(Vitamin value) => _save(value);
  Future<void> _save(Vitamin value) => store.save(
    kind: TreatmentSpecialization.vitamin,
    value: TreatmentProjection(
      id: value.id,
      name: value.name.value,
      hour: value.scheduleTime.hour,
      minute: value.scheduleTime.minute,
    ),
  );
  @override
  Future<void> delete(String id) => store.archive(id);
}

final class UnifiedVitaminLogRepository implements VitaminLogRepository {
  const UnifiedVitaminLogRepository(this.store);
  final UnifiedTreatmentStore store;

  @override
  Future<List<VitaminLog>> getByPeriod(DateTime start, DateTime end) async => [
    for (final value in await store.logs(
      TreatmentSpecialization.vitamin,
      start,
      end,
    ))
      VitaminLog(
        id: value.id,
        vitaminId: value.treatmentId,
        date: value.date,
        status: VitaminStatus.values.byName(value.state.name),
      ),
  ];

  @override
  Future<VitaminLog> setStatus({
    required String vitaminId,
    required DateTime date,
    required VitaminStatus status,
  }) async {
    final value = await store.setDailyState(
      kind: TreatmentSpecialization.vitamin,
      treatmentId: vitaminId,
      date: date,
      state: TreatmentDailyState.values.byName(status.name),
    );
    return VitaminLog(
      id: value.id,
      vitaminId: value.treatmentId,
      date: value.date,
      status: status,
    );
  }

  @override
  Future<void> deleteForVitamin(String vitaminId) async {}
}
