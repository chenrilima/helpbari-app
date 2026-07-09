import '../../../../core/database/database.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/sync/sync.dart';
import '../dtos/appointment_dto.dart';

class LocalAppointmentDatasource {
  const LocalAppointmentDatasource({
    required LocalDatabase database,
    required ClockService clock,
  }) : _database = database,
       _clock = clock;

  static const collection = 'appointments';

  final LocalDatabase _database;
  final ClockService _clock;

  Future<List<AppointmentDto>> getAll() async {
    final records = await _database.getAll(collection);
    final activeRecords = records.where((record) => !record.isDeleted).toList()
      ..sort((a, b) {
        final aDate = DateTime.parse(a.data['date'] as String);
        final bDate = DateTime.parse(b.data['date'] as String);

        return aDate.compareTo(bDate);
      });

    return activeRecords.map(AppointmentDto.fromRecord).toList();
  }

  Future<void> save(AppointmentDto appointment) async {
    final previous = await _database.getById(collection, appointment.id);
    final dto = AppointmentDto.fromEntity(
      appointment.toEntity(clock: _clock),
      now: _clock.now(),
      previousMetadata: previous?.metadata,
    );

    await _database.upsert(collection, dto.toRecord());
  }

  Future<void> delete(String id) async {
    final previous = await _database.getById(collection, id);
    if (previous == null) return;

    final now = _clock.now();
    await _database.upsert(
      collection,
      previous.copyWith(
        metadata: previous.metadata.copyWith(
          updatedAt: now,
          deletedAt: now,
          syncStatus: SyncStatus.pendingDelete,
        ),
      ),
    );
  }
}
