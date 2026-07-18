import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../../services/logger_service.dart';
import '../app_database.dart';

class ExamToMedicalExamMigrationReport {
  const ExamToMedicalExamMigrationReport({
    required this.usersProcessed,
    required this.recordsMigrated,
    required this.recordsSkipped,
    required this.recordsFailed,
  });

  final int usersProcessed;
  final int recordsMigrated;
  final int recordsSkipped;
  final int recordsFailed;
}

class ExamToMedicalExamMigrationService {
  const ExamToMedicalExamMigrationService({
    required AppDatabase database,
    required LoggerService logger,
  }) : _database = database,
       _logger = logger;

  static const migrationKeyPrefix = 'drift.exam_records_to_medical_exams.v1';

  final AppDatabase _database;
  final LoggerService _logger;

  Future<ExamToMedicalExamMigrationReport> migrate() async {
    final legacyRows =
        await (_database.select(_database.examRecords)..orderBy([
              (row) => OrderingTerm.asc(row.userId),
              (row) => OrderingTerm.asc(row.updatedAt),
            ]))
            .get();

    final byUser = <String, List<ExamRecord>>{};
    for (final row in legacyRows) {
      byUser.putIfAbsent(row.userId, () => <ExamRecord>[]).add(row);
    }

    var recordsMigrated = 0;
    var recordsSkipped = 0;
    var recordsFailed = 0;

    for (final entry in byUser.entries) {
      final userId = entry.key;
      final records = entry.value;
      final migrationKey = '$migrationKeyPrefix.$userId';
      final checksum = _checksum(records);

      for (final record in records) {
        try {
          final existing =
              await (_database.select(_database.medicalExams)..where(
                    (row) =>
                        row.userId.equals(record.userId) &
                        row.id.equals(record.id),
                  ))
                  .getSingleOrNull();
          if (existing != null) {
            recordsSkipped++;
            continue;
          }

          await _database
              .into(_database.medicalExams)
              .insertOnConflictUpdate(
                MedicalExamsCompanion.insert(
                  id: record.id,
                  userId: record.userId,
                  performedAt: record.examDate,
                  collectedAt: const Value.absent(),
                  receivedAt: const Value.absent(),
                  title: Value(record.name),
                  category: const Value.absent(),
                  laboratoryName: Value(record.laboratory),
                  professionalName: const Value.absent(),
                  requestProfessionalName: const Value.absent(),
                  documentNumber: const Value.absent(),
                  notes: Value(record.notes),
                  source: 'imported',
                  sourceDocumentId: const Value.absent(),
                  legacyAttachmentPath: Value(record.attachmentPath),
                  createdAt: record.createdAt,
                  updatedAt: record.updatedAt,
                  deletedAt: Value(record.deletedAt),
                  syncStatus: record.syncStatus,
                  previousSyncStatus: Value(record.previousSyncStatus),
                  syncAttempts: Value(record.syncAttempts),
                  lastSyncError: Value(record.lastSyncError),
                ),
              );
          recordsMigrated++;
        } catch (error, stackTrace) {
          recordsFailed++;
          _logger.warning(
            'Medical exam migration skipped one legacy exam record '
            '(${error.runtimeType}).',
          );
          _logger.error(
            'Medical exam migration record failure.',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }

      await _database
          .into(_database.localMigrations)
          .insertOnConflictUpdate(
            LocalMigrationsCompanion.insert(
              migrationKey: migrationKey,
              completedAt: DateTime.now().toUtc(),
              sourceChecksum: Value(checksum),
              importedCount: Value(records.length),
            ),
          );
    }

    final report = ExamToMedicalExamMigrationReport(
      usersProcessed: byUser.length,
      recordsMigrated: recordsMigrated,
      recordsSkipped: recordsSkipped,
      recordsFailed: recordsFailed,
    );
    _logger.info(
      'Medical exam migration completed: '
      'users=${report.usersProcessed}, '
      'migrated=${report.recordsMigrated}, '
      'skipped=${report.recordsSkipped}, '
      'failed=${report.recordsFailed}.',
    );
    return report;
  }

  String _checksum(List<ExamRecord> records) {
    final normalized = records
        .map(
          (record) => <String, Object?>{
            'userId': record.userId,
            'id': record.id,
            'name': record.name,
            'examDate': record.examDate.toUtc().toIso8601String(),
            'laboratory': record.laboratory,
            'notes': record.notes,
            'attachmentPath': record.attachmentPath,
            'createdAt': record.createdAt.toUtc().toIso8601String(),
            'updatedAt': record.updatedAt.toUtc().toIso8601String(),
            'deletedAt': record.deletedAt?.toUtc().toIso8601String(),
            'syncStatus': record.syncStatus,
            'previousSyncStatus': record.previousSyncStatus,
            'syncAttempts': record.syncAttempts,
            'lastSyncError': record.lastSyncError,
          },
        )
        .toList(growable: false);
    return sha256.convert(utf8.encode(jsonEncode(normalized))).toString();
  }
}
