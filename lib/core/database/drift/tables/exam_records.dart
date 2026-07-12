import 'package:drift/drift.dart';

@TableIndex(
  name: 'exam_user_deleted_date_idx',
  columns: {#userId, #deletedAt, #examDate},
)
@TableIndex(
  name: 'exam_user_sync_updated_idx',
  columns: {#userId, #syncStatus, #updatedAt},
)
class ExamRecords extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  DateTimeColumn get examDate => dateTime()();
  TextColumn get laboratory => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get attachmentPath => text().nullable()();
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
