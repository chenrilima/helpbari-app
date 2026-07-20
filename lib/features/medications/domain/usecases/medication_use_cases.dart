import '../entities/entities.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../value_objects/value_objects.dart';

class MedicationUseCases {
  const MedicationUseCases(
    this._repository, [
    this._logs,
    this._pendingCount,
    this._adherence,
  ]);
  final MedicationRepository _repository;
  final MedicationLogRepository? _logs;
  final Future<int> Function(DateTime date)? _pendingCount;
  final Future<double?> Function(DateTime start, DateTime end)? _adherence;
  Future<List<Medication>> getAll() => _repository.getAll();
  Future<void> save(Medication v) => _repository.save(v);
  Future<void> update(Medication v) => _repository.update(v);
  Future<void> delete(String id) => _repository.delete(id);
  Future<List<MedicationLog>> getLogs(DateTime start, DateTime end) =>
      _logs?.getByPeriod(start, end) ?? Future.value(const []);
  Future<int> getPendingCount({DateTime? date}) async {
    if (_pendingCount != null) {
      return _pendingCount(_day(date ?? DateTime.now()));
    }
    final medications = await getAll();
    final day = _day(date ?? DateTime.now());
    final logs = await getLogs(day, day);
    final resolved = logs
        .where((l) => l.status != MedicationStatus.pending)
        .map((l) => l.medicationId)
        .toSet();
    return medications.where((m) => !resolved.contains(m.id)).length;
  }

  Future<MedicationSummary> getSummary({DateTime? date}) async {
    final all = await getAll();
    return MedicationSummary(
      pendingCount: await getPendingCount(date: date),
      hasMedications: all.isNotEmpty,
    );
  }

  Future<MedicationLog> setDailyStatus(
    String id,
    MedicationStatus status, {
    DateTime? date,
  }) => _logs == null
      ? Future.error(StateError('Histórico diário indisponível.'))
      : _logs.setStatus(
          medicationId: id,
          date: _day(date ?? DateTime.now()),
          status: status,
        );
  Future<void> markAsTaken(String id) async {
    await setDailyStatus(id, MedicationStatus.taken);
  }

  Future<void> markAsSkipped(String id) async {
    await setDailyStatus(id, MedicationStatus.skipped);
  }

  Future<void> resetStatus(String id) async {
    await setDailyStatus(id, MedicationStatus.pending);
  }

  Future<double?> adherence(DateTime start, DateTime end) async {
    if (_adherence != null) return _adherence(_day(start), _day(end));
    final logs = await getLogs(_day(start), _day(end));
    final resolved = logs
        .where((l) => l.status != MedicationStatus.pending)
        .toList();
    if (resolved.isEmpty) return null;
    return resolved.where((l) => l.status == MedicationStatus.taken).length /
        resolved.length *
        100;
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
}
