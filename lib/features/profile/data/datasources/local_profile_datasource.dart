import '../../../../core/database/database.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/sync/sync.dart';
import '../dtos/profile_dto.dart';

class LocalProfileDatasource {
  const LocalProfileDatasource({
    required LocalDatabase database,
    required ClockService clock,
  }) : _database = database,
       _clock = clock;

  static const collection = 'profiles';

  final LocalDatabase _database;
  final ClockService _clock;

  Future<ProfileDto?> getProfile() async {
    final records = await _database.getAll(collection);
    final activeRecords = records.where((record) => !record.isDeleted).toList()
      ..sort((a, b) => b.metadata.updatedAt.compareTo(a.metadata.updatedAt));

    if (activeRecords.isEmpty) return null;

    return ProfileDto.fromRecord(activeRecords.first);
  }

  Future<void> save(ProfileDto profile) async {
    final previous = await _database.getById(collection, profile.id);
    final dto = ProfileDto.fromEntity(
      profile.toEntity(clock: _clock),
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
