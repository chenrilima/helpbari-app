import '../../../../core/database/database.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/sync/sync.dart';
import '../dtos/vitamin_dto.dart';

class LocalVitaminDatasource {
  const LocalVitaminDatasource({
    required LocalDatabase database,
    required ClockService clock,
  }) : _database = database,
       _clock = clock;

  static const collection = 'vitamins';

  final LocalDatabase _database;
  final ClockService _clock;

  Future<List<VitaminDto>> getAll() async {
    final records = await _database.getAll(collection);
    final activeRecords = records.where((record) => !record.isDeleted).toList()
      ..sort((a, b) {
        final hourComparison = (a.data['hour'] as int).compareTo(
          b.data['hour'] as int,
        );
        if (hourComparison != 0) return hourComparison;

        return (a.data['minute'] as int).compareTo(b.data['minute'] as int);
      });

    return activeRecords.map(VitaminDto.fromRecord).toList();
  }

  Future<void> save(VitaminDto vitamin) async {
    final previous = await _database.getById(collection, vitamin.id);
    final dto = VitaminDto.fromEntity(
      vitamin.toEntity(),
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
