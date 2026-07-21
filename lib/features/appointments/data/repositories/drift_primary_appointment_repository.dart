import '../../../../core/services/logger_service.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../datasources/drift_appointment_local_datasource.dart';
import '../datasources/local_appointment_datasource.dart';
import '../dtos/appointment_dto.dart';

typedef EnsureAppointmentCutover = Future<void> Function();
typedef HasAppointmentCutoverMirror = bool Function();
Future<void> _noop() async {}
bool _noMirror() => false;

class DriftPrimaryAppointmentRepository
    implements AppointmentRepository, AppointmentRangeRepository {
  const DriftPrimaryAppointmentRepository({
    required Future<DriftAppointmentLocalDatasource> Function() drift,
    required LocalAppointmentDatasource fallback,
    required LoggerService logger,
    EnsureAppointmentCutover ensureCutover = _noop,
    HasAppointmentCutoverMirror hasCutoverMirror = _noMirror,
  }) : _drift = drift,
       _fallback = fallback,
       _logger = logger,
       _ensureCutover = ensureCutover,
       _hasCutoverMirror = hasCutoverMirror;
  final Future<DriftAppointmentLocalDatasource> Function() _drift;
  final LocalAppointmentDatasource _fallback;
  final LoggerService _logger;
  final EnsureAppointmentCutover _ensureCutover;
  final HasAppointmentCutoverMirror _hasCutoverMirror;
  Future<DriftAppointmentLocalDatasource> _resolve() async {
    final value = await _drift();
    await _ensureCutover();
    return value;
  }

  @override
  Future<List<Appointment>> getAll() async {
    try {
      return (await (await _resolve()).getAll())
          .map((e) => e.toEntity())
          .toList();
    } catch (error) {
      if (_hasCutoverMirror()) {
        throw StateError('Consultas indisponíveis temporariamente.');
      }
      _logger.warning(
        'Appointments Drift unavailable; legacy fallback (${error.runtimeType}).',
      );
      return (await _fallback.getAll()).map((e) => e.toEntity()).toList();
    }
  }

  @override
  Future<List<Appointment>> getByPeriod(
    DateTime startInclusive,
    DateTime endExclusive, {
    required int limit,
  }) async => (await (await _resolve()).getByPeriod(
    startInclusive,
    endExclusive,
    limit: limit,
  )).map((dto) => dto.toEntity()).toList();

  Future<void> _save(Appointment value) async => (await _resolve()).save(
    AppointmentDto.fromEntity(value, now: DateTime.now()),
  );
  @override
  Future<void> save(Appointment appointment) => _save(appointment);
  @override
  Future<void> update(Appointment appointment) => _save(appointment);
  @override
  Future<void> delete(String id) async => (await _resolve()).delete(id);
}
