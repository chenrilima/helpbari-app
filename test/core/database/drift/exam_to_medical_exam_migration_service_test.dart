import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/drift/app_database.dart';
import 'package:helpbari/core/database/drift/migrations/exam_to_medical_exam_migration_service.dart';
import 'package:helpbari/core/services/logger_service.dart';

void main() {
  late AppDatabase database;
  late _RecordingLogger logger;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    logger = _RecordingLogger();
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'migrates a single legacy exam preserving fields without results',
    () async {
      final now = DateTime.utc(2026, 7, 18, 10);
      await database
          .into(database.examRecords)
          .insert(
            ExamRecordsCompanion.insert(
              id: 'legacy-1',
              userId: 'user-a',
              name: 'Hemograma completo',
              examDate: now,
              laboratory: const Value('Lab A'),
              notes: const Value('Trazer na consulta'),
              attachmentPath: const Value('/tmp/exam-1.jpg'),
              createdAt: now,
              updatedAt: now,
              deletedAt: const Value.absent(),
              syncStatus: 'pendingCreate',
            ),
          );

      final report = await ExamToMedicalExamMigrationService(
        database: database,
        logger: logger,
      ).migrate();

      final exam =
          await (database.select(database.medicalExams)..where(
                (row) =>
                    row.userId.equals('user-a') & row.id.equals('legacy-1'),
              ))
              .getSingle();
      final legacy =
          await (database.select(database.examRecords)..where(
                (row) =>
                    row.userId.equals('user-a') & row.id.equals('legacy-1'),
              ))
              .getSingle();
      final results =
          await (database.select(database.medicalExamResults)..where(
                (row) =>
                    row.userId.equals('user-a') &
                    row.medicalExamId.equals('legacy-1'),
              ))
              .get();

      expect(report.recordsMigrated, 1);
      expect(report.recordsFailed, 0);
      expect(exam.title, 'Hemograma completo');
      expect(exam.performedAt.toUtc(), now);
      expect(exam.laboratoryName, 'Lab A');
      expect(exam.notes, 'Trazer na consulta');
      expect(exam.legacyAttachmentPath, '/tmp/exam-1.jpg');
      expect(exam.source, 'imported');
      expect(exam.syncStatus, 'pendingCreate');
      expect(legacy.id, 'legacy-1');
      expect(results, isEmpty);
    },
  );

  test(
    'migrates several users without duplication on second execution',
    () async {
      final now = DateTime.utc(2026, 7, 18, 11);
      await _insertLegacy(
        database: database,
        id: 'exam-a1',
        userId: 'user-a',
        name: 'Ferritina',
        examDate: now,
        updatedAt: now,
      );
      await _insertLegacy(
        database: database,
        id: 'exam-a2',
        userId: 'user-a',
        name: 'Vitamina B12',
        examDate: now.subtract(const Duration(days: 1)),
        updatedAt: now,
        laboratory: 'Lab A',
        notes: 'Monitorar',
      );
      await _insertLegacy(
        database: database,
        id: 'exam-b1',
        userId: 'user-b',
        name: 'Vitamina D',
        examDate: now.subtract(const Duration(days: 2)),
        updatedAt: now,
        attachmentPath: '/tmp/b1.pdf',
      );

      final service = ExamToMedicalExamMigrationService(
        database: database,
        logger: logger,
      );

      final first = await service.migrate();
      final second = await service.migrate();

      final all = await database.select(database.medicalExams).get();

      expect(first.recordsMigrated, 3);
      expect(second.recordsMigrated, 0);
      expect(second.recordsSkipped, 3);
      expect(all, hasLength(3));
      expect(
        all.where((item) => item.userId == 'user-a').map((item) => item.id),
        containsAll(<String>['exam-a1', 'exam-a2']),
      );
      expect(
        all
            .where((item) => item.userId == 'user-b')
            .single
            .legacyAttachmentPath,
        '/tmp/b1.pdf',
      );
    },
  );

  test(
    'skips destination already existing and does not overwrite newer data',
    () async {
      final legacyUpdatedAt = DateTime.utc(2026, 7, 18, 9);
      final newUpdatedAt = DateTime.utc(2026, 7, 18, 12);
      await _insertLegacy(
        database: database,
        id: 'shared-id',
        userId: 'user-a',
        name: 'Nome legado',
        examDate: legacyUpdatedAt,
        updatedAt: legacyUpdatedAt,
        laboratory: 'Lab legado',
        notes: 'nota legada',
      );
      await database
          .into(database.medicalExams)
          .insert(
            MedicalExamsCompanion.insert(
              id: 'shared-id',
              userId: 'user-a',
              performedAt: legacyUpdatedAt,
              collectedAt: const Value.absent(),
              receivedAt: const Value.absent(),
              title: const Value('Nome novo'),
              category: const Value.absent(),
              laboratoryName: const Value('Lab novo'),
              professionalName: const Value.absent(),
              requestProfessionalName: const Value.absent(),
              documentNumber: const Value.absent(),
              notes: const Value('nota nova'),
              source: 'manual',
              sourceDocumentId: const Value.absent(),
              legacyAttachmentPath: const Value('/tmp/new.pdf'),
              createdAt: legacyUpdatedAt,
              updatedAt: newUpdatedAt,
              deletedAt: const Value.absent(),
              syncStatus: 'pendingUpdate',
            ),
          );

      final report = await ExamToMedicalExamMigrationService(
        database: database,
        logger: logger,
      ).migrate();

      final exam =
          await (database.select(database.medicalExams)..where(
                (row) =>
                    row.userId.equals('user-a') & row.id.equals('shared-id'),
              ))
              .getSingle();

      expect(report.recordsMigrated, 0);
      expect(report.recordsSkipped, 1);
      expect(exam.title, 'Nome novo');
      expect(exam.laboratoryName, 'Lab novo');
      expect(exam.notes, 'nota nova');
      expect(exam.legacyAttachmentPath, '/tmp/new.pdf');
      expect(exam.updatedAt.toUtc(), newUpdatedAt);
    },
  );

  test('preserves tombstone and sync metadata', () async {
    final now = DateTime.utc(2026, 7, 18, 13);
    final deletedAt = now.add(const Duration(hours: 1));
    await database
        .into(database.examRecords)
        .insert(
          ExamRecordsCompanion.insert(
            id: 'deleted-exam',
            userId: 'user-a',
            name: 'Colesterol',
            examDate: now,
            laboratory: const Value('Lab X'),
            notes: const Value('apagado'),
            attachmentPath: const Value('/tmp/deleted.pdf'),
            createdAt: now,
            updatedAt: deletedAt,
            deletedAt: Value(deletedAt),
            syncStatus: 'pendingDelete',
            previousSyncStatus: const Value('synced'),
            syncAttempts: const Value(2),
            lastSyncError: const Value('network'),
          ),
        );

    await ExamToMedicalExamMigrationService(
      database: database,
      logger: logger,
    ).migrate();

    final exam =
        await (database.select(database.medicalExams)..where(
              (row) =>
                  row.userId.equals('user-a') & row.id.equals('deleted-exam'),
            ))
            .getSingle();

    expect(exam.deletedAt?.toUtc(), deletedAt);
    expect(exam.syncStatus, 'pendingDelete');
    expect(exam.previousSyncStatus, 'synced');
    expect(exam.syncAttempts, 2);
    expect(exam.lastSyncError, 'network');
  });

  test(
    'isolates per-record failure and continues migrating other records',
    () async {
      final now = DateTime.utc(2026, 7, 18, 14);
      await _insertLegacy(
        database: database,
        id: 'good',
        userId: 'user-a',
        name: 'Glicose',
        examDate: now,
        updatedAt: now,
      );
      await _insertLegacy(
        database: database,
        id: 'bad',
        userId: 'user-a',
        name: 'TSH',
        examDate: now,
        updatedAt: now,
      );
      await database.customStatement('''
      CREATE TRIGGER reject_bad_medical_exam
      BEFORE INSERT ON medical_exams
      WHEN NEW.id = 'bad'
      BEGIN
        SELECT RAISE(ABORT, 'bad row');
      END;
    ''');

      final report = await ExamToMedicalExamMigrationService(
        database: database,
        logger: logger,
      ).migrate();

      final migrated = await database.select(database.medicalExams).get();

      expect(report.recordsMigrated, 1);
      expect(report.recordsFailed, 1);
      expect(migrated.map((item) => item.id), contains('good'));
      expect(migrated.map((item) => item.id), isNot(contains('bad')));
      expect(logger.errors, isNotEmpty);
    },
  );
}

class _RecordingLogger implements LoggerService {
  final List<String> infos = <String>[];
  final List<String> warnings = <String>[];
  final List<String> errors = <String>[];

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    errors.add(message);
  }

  @override
  void info(String message) {
    infos.add(message);
  }

  @override
  void warning(String message) {
    warnings.add(message);
  }
}

Future<void> _insertLegacy({
  required AppDatabase database,
  required String id,
  required String userId,
  required String name,
  required DateTime examDate,
  required DateTime updatedAt,
  String? laboratory,
  String? notes,
  String? attachmentPath,
}) {
  return database
      .into(database.examRecords)
      .insert(
        ExamRecordsCompanion.insert(
          id: id,
          userId: userId,
          name: name,
          examDate: examDate,
          laboratory: Value(laboratory),
          notes: Value(notes),
          attachmentPath: Value(attachmentPath),
          createdAt: updatedAt,
          updatedAt: updatedAt,
          deletedAt: const Value.absent(),
          syncStatus: 'pendingCreate',
        ),
      );
}
