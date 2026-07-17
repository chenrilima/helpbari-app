import 'package:drift/drift.dart';

@TableIndex(
  name: 'bioimpedance_user_deleted_measured_idx',
  columns: {#userId, #deletedAt, #measuredAt},
)
@TableIndex(
  name: 'bioimpedance_user_sync_updated_idx',
  columns: {#userId, #syncStatus, #updatedAt},
)
class BioimpedanceRecords extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get measuredAt => dateTime()();
  RealColumn get weightKg => real().nullable()();
  RealColumn get muscleMassKg => real().nullable()();
  RealColumn get bodyFatMassKg => real().nullable()();
  RealColumn get bodyWaterPercentage => real().nullable()();
  RealColumn get bodyFatPercentage => real().nullable()();
  RealColumn get skeletalMuscleMassKg => real().nullable()();
  RealColumn get leanBodyMassKg => real().nullable()();
  RealColumn get fatFreeMassKg => real().nullable()();
  RealColumn get visceralFatLevel => real().nullable()();
  RealColumn get visceralFatAreaCm2 => real().nullable()();
  RealColumn get subcutaneousFatPercentage => real().nullable()();
  RealColumn get proteinPercentage => real().nullable()();
  RealColumn get mineralMassKg => real().nullable()();
  RealColumn get boneMassKg => real().nullable()();
  RealColumn get bmi => real().nullable()();
  RealColumn get basalMetabolicRateKcal => real().nullable()();
  IntColumn get metabolicAge => integer().nullable()();
  RealColumn get waistHipRatio => real().nullable()();
  RealColumn get waistCircumferenceCm => real().nullable()();
  RealColumn get hipCircumferenceCm => real().nullable()();
  RealColumn get bodyCellMassKg => real().nullable()();
  RealColumn get intracellularWaterLiters => real().nullable()();
  RealColumn get extracellularWaterLiters => real().nullable()();
  RealColumn get totalBodyWaterLiters => real().nullable()();
  RealColumn get phaseAngleDegrees => real().nullable()();
  RealColumn get bodyScore => real().nullable()();
  RealColumn get recommendedWeightKg => real().nullable()();
  RealColumn get weightControlKg => real().nullable()();
  RealColumn get fatControlKg => real().nullable()();
  RealColumn get muscleControlKg => real().nullable()();
  TextColumn get deviceName => text().nullable()();
  TextColumn get clinicName => text().nullable()();
  TextColumn get professionalName => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get sourceDocumentId => text().nullable()();
  TextColumn get source => text()();
  TextColumn get additionalMetricsJson =>
      text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text()();
  TextColumn get previousSyncStatus => text().nullable()();
  IntColumn get syncAttempts => integer().withDefault(const Constant(0))();
  TextColumn get lastSyncError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {userId, id};
}
