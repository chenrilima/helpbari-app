import '../../../../core/database/database.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/sync/sync.dart';
import '../../domain/entities/entities.dart';
import '../../domain/value_objects/value_objects.dart';

class MealDto {
  const MealDto({
    required this.id,
    required this.name,
    required this.type,
    required this.mealDate,
    required this.syncMetadata,
    this.notes,
    this.proteinGrams,
  });

  final String id;
  final String name;
  final MealType type;
  final DateTime mealDate;
  final String? notes;
  final int? proteinGrams;
  final SyncMetadata syncMetadata;

  Meal toEntity({ClockService clock = const AppClockService()}) {
    final mealName = MealName.create(name);

    if (mealName == null) {
      throw FormatException('Refeição local inválida: $id');
    }

    return Meal(
      id: id,
      name: mealName,
      type: type,
      mealDate: MealDate(mealDate, clock: clock),
      notes: notes,
      proteinGrams: proteinGrams,
    );
  }

  LocalDatabaseRecord toRecord() {
    return LocalDatabaseRecord(
      metadata: syncMetadata,
      data: {
        'name': name,
        'type': type.name,
        'mealDate': mealDate.toIso8601String(),
        'notes': notes,
        'proteinGrams': proteinGrams,
      },
    );
  }

  static MealDto fromEntity(
    Meal meal, {
    required DateTime now,
    SyncMetadata? previousMetadata,
  }) {
    return MealDto(
      id: meal.id,
      name: meal.name.value,
      type: meal.type,
      mealDate: meal.mealDate.value,
      notes: meal.notes,
      proteinGrams: meal.proteinGrams,
      syncMetadata: SyncMetadata(
        id: meal.id,
        userId: previousMetadata?.userId,
        createdAt: previousMetadata?.createdAt ?? now,
        updatedAt: now,
        syncStatus: _nextSyncStatus(previousMetadata?.syncStatus),
      ),
    );
  }

  static MealDto fromRecord(LocalDatabaseRecord record) {
    final data = record.data;

    return MealDto(
      id: record.id,
      name: data['name'] as String,
      type: MealType.values.firstWhere(
        (type) => type.name == data['type'],
        orElse: () => MealType.snack,
      ),
      mealDate: DateTime.parse(data['mealDate'] as String),
      notes: data['notes'] as String?,
      proteinGrams: data['proteinGrams'] as int?,
      syncMetadata: record.metadata,
    );
  }

  static SyncStatus _nextSyncStatus(SyncStatus? currentStatus) {
    return switch (currentStatus) {
      SyncStatus.synced => SyncStatus.pendingUpdate,
      SyncStatus.failed => SyncStatus.pendingUpdate,
      SyncStatus.pendingDelete => SyncStatus.pendingUpdate,
      SyncStatus.pendingCreate => SyncStatus.pendingCreate,
      SyncStatus.pendingUpdate => SyncStatus.pendingUpdate,
      null => SyncStatus.pendingCreate,
    };
  }
}
