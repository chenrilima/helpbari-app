import '../../../../core/database/database.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/sync/sync.dart';
import '../dtos/meal_dto.dart';

class LocalMealDatasource {
  const LocalMealDatasource({
    required LocalDatabase database,
    required ClockService clock,
  }) : _database = database,
       _clock = clock;

  static const collection = 'meals';

  final LocalDatabase _database;
  final ClockService _clock;

  Future<List<MealDto>> getAll() async {
    final records = await _database.getAll(collection);
    final activeRecords = records.where((record) => !record.isDeleted).toList()
      ..sort((a, b) {
        final aDate = DateTime.parse(a.data['mealDate'] as String);
        final bDate = DateTime.parse(b.data['mealDate'] as String);

        return bDate.compareTo(aDate);
      });

    return activeRecords.map(MealDto.fromRecord).toList();
  }

  Future<void> save(MealDto meal) async {
    final previous = await _database.getById(collection, meal.id);
    final dto = MealDto.fromEntity(
      meal.toEntity(clock: _clock),
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
