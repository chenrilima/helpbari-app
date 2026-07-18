import 'package:drift/drift.dart';

@TableIndex(
  name: 'medical_exam_results_user_exam_sort_idx',
  columns: {#userId, #medicalExamId, #sortOrder},
)
@TableIndex(
  name: 'medical_exam_results_user_deleted_updated_idx',
  columns: {#userId, #deletedAt, #updatedAt},
)
@TableIndex(
  name: 'medical_exam_results_user_canonical_code_idx',
  columns: {#userId, #canonicalCode},
)
@TableIndex(
  name: 'medical_exam_results_user_normalized_name_idx',
  columns: {#userId, #normalizedName},
)
class MedicalExamResults extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get medicalExamId => text()();
  TextColumn get canonicalCode => text().nullable()();
  TextColumn get canonicalName => text()();
  TextColumn get displayName => text()();
  TextColumn get normalizedName => text()();
  TextColumn get category => text().nullable()();
  TextColumn get valueType => text()();
  RealColumn get numericValue => real().nullable()();
  TextColumn get textValue => text().nullable()();
  BoolColumn get booleanValue => boolean().nullable()();
  TextColumn get qualitativeValue => text().nullable()();
  TextColumn get unit => text().nullable()();
  TextColumn get normalizedUnit => text().nullable()();
  TextColumn get referenceRangeText => text().nullable()();
  RealColumn get referenceMin => real().nullable()();
  RealColumn get referenceMax => real().nullable()();
  TextColumn get referenceComparator => text().nullable()();
  TextColumn get referenceContext => text().nullable()();
  TextColumn get status => text().nullable()();
  TextColumn get method => text().nullable()();
  TextColumn get specimen => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get originalText => text().nullable()();
  TextColumn get source => text()();
  RealColumn get confidence => real().nullable()();
  IntColumn get sortOrder => integer()();
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
