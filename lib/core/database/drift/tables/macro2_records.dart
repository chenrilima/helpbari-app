import 'package:drift/drift.dart';

mixin Macro2SyncColumns on Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text()();

  @override
  Set<Column<Object>> get primaryKey => {userId, id};
}

@TableIndex(
  name: 'prescription_versions_parent_revision_idx',
  columns: {#userId, #prescriptionId, #revision},
  unique: true,
)
@TableIndex(
  name: 'prescription_versions_source_processing_idx',
  columns: {#userId, #sourceProcessingId},
  unique: true,
)
class PrescriptionVersionRecords extends Table with Macro2SyncColumns {
  TextColumn get prescriptionId => text()();
  IntColumn get revision => integer()();
  TextColumn get status => text()();
  TextColumn get snapshotJson => text()();
  TextColumn get sourceProcessingId => text().nullable()();
  DateTimeColumn get submittedAt => dateTime().nullable()();
  DateTimeColumn get confirmedAt => dateTime().nullable()();
}

@TableIndex(
  name: 'prescription_reviews_version_idx',
  columns: {#userId, #versionId, #createdAt},
)
class PrescriptionReviewRecords extends Table with Macro2SyncColumns {
  TextColumn get prescriptionId => text()();
  TextColumn get versionId => text()();
  TextColumn get decision => text()();
  TextColumn get actor => text()();
  TextColumn get fieldDecisionsJson => text()();
  TextColumn get note => text().nullable()();
}

@TableIndex(
  name: 'treatment_proposals_item_version_idx',
  columns: {#userId, #prescriptionItemId, #prescriptionVersionId},
  unique: true,
)
class TreatmentProposalRecords extends Table with Macro2SyncColumns {
  TextColumn get prescriptionId => text()();
  TextColumn get prescriptionVersionId => text()();
  TextColumn get prescriptionItemId => text()();
  TextColumn get decision => text()();
  TextColumn get draftJson => text()();
  TextColumn get targetRoutineId => text().nullable()();
  TextColumn get resultingPlanId => text().nullable()();
  DateTimeColumn get confirmedAt => dateTime().nullable()();
}

@TableIndex(
  name: 'prescription_routine_links_item_idx',
  columns: {#userId, #prescriptionItemId, #active},
)
class PrescriptionRoutineLinkRecords extends Table with Macro2SyncColumns {
  TextColumn get prescriptionId => text()();
  TextColumn get prescriptionVersionId => text()();
  TextColumn get prescriptionItemId => text()();
  TextColumn get routineId => text()();
  TextColumn get planId => text()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
}

@TableIndex(
  name: 'notification_manifest_user_schedule_idx',
  columns: {#userId, #scheduledAtUtc},
)
class NotificationManifestRecords extends Table {
  TextColumn get key => text()();
  TextColumn get userId => text()();
  TextColumn get occurrenceId => text()();
  IntColumn get pluginId => integer()();
  TextColumn get projectionVersion => text()();
  DateTimeColumn get scheduledAtUtc => dateTime()();
  TextColumn get payloadJson => text()();
  TextColumn get state => text()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get retryAfterUtc => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {userId, key};
}

@TableIndex(
  name: 'notification_action_inbox_pending_idx',
  columns: {#userId, #state, #receivedAtUtc},
)
class NotificationActionInboxRecords extends Table {
  TextColumn get actionId => text()();
  TextColumn get userId => text()();
  TextColumn get occurrenceId => text()();
  TextColumn get action => text()();
  DateTimeColumn get occurredAtUtc => dateTime()();
  DateTimeColumn get receivedAtUtc => dateTime()();
  TextColumn get state => text()();
  TextColumn get errorCode => text().nullable()();
  DateTimeColumn get processedAtUtc => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {userId, actionId};
}
