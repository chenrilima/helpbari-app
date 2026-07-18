import 'package:drift/drift.dart' show Value;

import '../../../../core/database/drift/app_database.dart' as db;
import '../../../../core/database/drift/daos/medical_exam_dao.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/sync/sync.dart';
import '../../domain/entities/entities.dart';
import '../dtos/medical_exam_dto.dart';
import '../dtos/medical_exam_result_dto.dart';

const anonymousMedicalExamUserId = 'anonymous';

class DriftMedicalExamLocalDatasource {
  const DriftMedicalExamLocalDatasource({
    required MedicalExamDao dao,
    required ClockService clock,
    required this.userId,
  }) : _dao = dao,
       _clock = clock;

  final MedicalExamDao _dao;
  final ClockService _clock;
  final String userId;

  bool get canSync => userId != anonymousMedicalExamUserId;

  Future<List<MedicalExam>> getHistory() async {
    final exams = await _dao.getActiveExamsByUser(userId);
    final items = <MedicalExam>[];
    for (final exam in exams) {
      final results = await _dao.getActiveResultsByExam(userId, exam.id);
      items.add(_fromDrift(exam, results));
    }
    return items;
  }

  Future<MedicalExam?> getById(String id) async {
    final exam = await _dao.getExamByUserAndId(userId, id);
    if (exam == null || exam.deletedAt != null) return null;
    final results = await _dao.getActiveResultsByExam(userId, id);
    return _fromDrift(exam, results);
  }

  Future<void> save(MedicalExam exam) async {
    if (!exam.hasAnyContent) {
      throw const FormatException(
        'Informe um título ou ao menos um resultado válido.',
      );
    }
    final previous = await _pendingById(exam.id);
    final previousById = {
      for (final item in previous?.results ?? const <MedicalExamResultDto>[])
        item.result.id: item.syncMetadata,
    };
    final dto = MedicalExamDto.fromEntity(
      exam,
      now: _clock.now(),
      previousMetadata: previous?.syncMetadata,
      previousResultMetadata: previousById,
    );

    final previousResults = previous?.results ?? const <MedicalExamResultDto>[];
    final previousRowsById = {
      for (final item in previousResults) item.result.id: item,
    };
    final nextResultIds = dto.results.map((item) => item.result.id).toSet();
    final removedResults = previousRowsById.values
        .where((item) => !nextResultIds.contains(item.result.id))
        .map(
          (item) => MedicalExamResultDto(
            result: item.result.copyWith(
              updatedAt: dto.syncMetadata.updatedAt,
              deletedAt: dto.syncMetadata.updatedAt,
              syncStatus: SyncStatus.pendingDelete,
            ),
            syncMetadata: item.syncMetadata.copyWith(
              updatedAt: dto.syncMetadata.updatedAt,
              deletedAt: dto.syncMetadata.updatedAt,
              syncStatus: SyncStatus.pendingDelete,
            ),
          ),
        )
        .toList(growable: false);

    await _dao.inTransaction(() async {
      await _dao.upsertExam(_examCompanion(dto.exam, dto.syncMetadata));
      for (final item in dto.results) {
        await _dao.upsertResult(
          _resultCompanion(item.result, item.syncMetadata),
        );
      }
      for (final item in removedResults) {
        await _dao.upsertResult(
          _resultCompanion(item.result, item.syncMetadata),
        );
      }
    });
  }

  Future<void> delete(String id) async {
    final previous = await _pendingById(id);
    if (previous == null) return;
    final now = _clock.now();
    final deletedExam = previous.exam.copyWith(
      updatedAt: now,
      deletedAt: now,
      syncStatus: SyncStatus.pendingDelete,
      results: previous.results
          .map(
            (item) => item.result.copyWith(
              updatedAt: now,
              deletedAt: now,
              syncStatus: SyncStatus.pendingDelete,
            ),
          )
          .toList(growable: false),
    );
    final dto = MedicalExamDto(
      exam: deletedExam,
      results: deletedExam.results
          .map(
            (item) => MedicalExamResultDto(
              result: item,
              syncMetadata: previous.results
                  .firstWhere((row) => row.result.id == item.id)
                  .syncMetadata
                  .copyWith(
                    updatedAt: now,
                    deletedAt: now,
                    syncStatus: SyncStatus.pendingDelete,
                  ),
            ),
          )
          .toList(growable: false),
      syncMetadata: previous.syncMetadata.copyWith(
        updatedAt: now,
        deletedAt: now,
        syncStatus: SyncStatus.pendingDelete,
      ),
    );
    await _dao.inTransaction(() async {
      await _dao.upsertExam(_examCompanion(dto.exam, dto.syncMetadata));
      for (final item in dto.results) {
        await _dao.upsertResult(
          _resultCompanion(item.result, item.syncMetadata),
        );
      }
    });
  }

  Future<List<MedicalExamDto>> pendingSync() async => canSync
      ? _pendingSyncDtos(await _dao.getPendingExamsForSync(userId))
      : const [];

  Future<MedicalExamDto?> pendingById(String id) => _pendingById(id);

  Future<void> applyRemote(MedicalExamDto remote) async {
    if (!canSync || remote.syncMetadata.userId != userId) return;
    final local = await _pendingById(remote.exam.id);
    if (local != null &&
        !remote.syncMetadata.updatedAt.isAfter(local.syncMetadata.updatedAt)) {
      return;
    }
    await _dao.inTransaction(() async {
      await _dao.upsertExam(_examCompanion(remote.exam, remote.syncMetadata));
      final existing = await _dao.getResultsByExamIncludingDeleted(
        userId,
        remote.exam.id,
      );
      final existingById = {for (final row in existing) row.id: row};
      final nextIds = remote.results.map((item) => item.result.id).toSet();
      for (final item in remote.results) {
        await _dao.upsertResult(
          _resultCompanion(item.result, item.syncMetadata),
        );
      }
      for (final row in existing) {
        if (nextIds.contains(row.id)) continue;
        final metadata = SyncMetadata(
          id: row.id,
          userId: row.userId,
          createdAt: row.createdAt,
          updatedAt: remote.syncMetadata.updatedAt,
          deletedAt: remote.syncMetadata.updatedAt,
          syncStatus: SyncStatus.synced,
        );
        await _dao.upsertResult(
          _syncCopyResult(
            existingById[row.id]!,
            status: SyncStatus.synced,
            previousStatus: null,
            attempts: 0,
            error: null,
            updatedAt: remote.syncMetadata.updatedAt,
            deletedAt: metadata.deletedAt,
          ),
        );
      }
    });
  }

  Future<void> applyRemoteAndMarkSynced(MedicalExamDto remote) =>
      _dao.inTransaction(() async {
        await applyRemote(remote);
        await markSynced(remote.exam.id);
      });

  Future<void> markSynced(String id) async {
    final dto = await _pendingById(id);
    if (dto == null) return;
    final examRow = await _dao.getExamByUserAndId(userId, id);
    if (examRow == null) return;
    await _dao.inTransaction(() async {
      await _dao.upsertExam(
        _syncCopyExam(
          examRow,
          status: SyncStatus.synced,
          previousStatus: null,
          attempts: 0,
          error: null,
        ),
      );
      final resultRows = await _dao.getResultsByExamIncludingDeleted(
        userId,
        id,
      );
      for (final row in resultRows) {
        await _dao.upsertResult(
          _syncCopyResult(
            row,
            status: SyncStatus.synced,
            previousStatus: null,
            attempts: 0,
            error: null,
          ),
        );
      }
    });
  }

  Future<void> markFailed(String id, String message) async {
    final examRow = await _dao.getExamByUserAndId(userId, id);
    if (examRow == null) return;
    await _dao.inTransaction(() async {
      await _dao.upsertExam(
        _syncCopyExam(
          examRow,
          status: SyncStatus.failed,
          previousStatus: examRow.previousSyncStatus ?? examRow.syncStatus,
          attempts: examRow.syncAttempts + 1,
          error: message,
        ),
      );
      final resultRows = await _dao.getResultsByExamIncludingDeleted(
        userId,
        id,
      );
      for (final row in resultRows.where(
        (row) => row.syncStatus != SyncStatus.synced.name,
      )) {
        await _dao.upsertResult(
          _syncCopyResult(
            row,
            status: SyncStatus.failed,
            previousStatus: row.previousSyncStatus ?? row.syncStatus,
            attempts: row.syncAttempts + 1,
            error: message,
          ),
        );
      }
    });
  }

  Future<DateTime?> getLastPullAt(String key) =>
      _dao.getLastPullAt(userId, key);

  Future<void> saveCursor(String key, DateTime at) =>
      _dao.saveCursor(userId, key, at);

  Future<List<MedicalExamDto>> _pendingSyncDtos(
    List<db.MedicalExam> rows,
  ) async {
    final items = <MedicalExamDto>[];
    for (final row in rows) {
      final dto = await _pendingById(row.id);
      if (dto != null) items.add(dto);
    }
    return items;
  }

  Future<MedicalExamDto?> _pendingById(String id) async {
    final exam = await _dao.getExamByUserAndId(userId, id);
    if (exam == null) return null;
    final resultRows = await _dao.getResultsByExamIncludingDeleted(userId, id);
    final results = resultRows.map(_pendingResultDto).toList(growable: false);
    final activeResults = resultRows
        .where((item) => item.deletedAt == null)
        .toList();
    final entity = _fromDrift(exam, activeResults);
    final status = exam.syncStatus == SyncStatus.failed.name
        ? SyncStatus.fromName(exam.previousSyncStatus)
        : SyncStatus.fromName(exam.syncStatus);
    return MedicalExamDto(
      exam: entity.copyWith(
        results: results.map((item) => item.result).toList(growable: false),
      ),
      results: results,
      syncMetadata: SyncMetadata(
        id: exam.id,
        userId: exam.userId,
        createdAt: exam.createdAt,
        updatedAt: exam.updatedAt,
        deletedAt: exam.deletedAt,
        syncStatus: status,
      ),
    );
  }

  MedicalExamResultDto _pendingResultDto(db.MedicalExamResult row) {
    final status = row.syncStatus == SyncStatus.failed.name
        ? SyncStatus.fromName(row.previousSyncStatus)
        : SyncStatus.fromName(row.syncStatus);
    return MedicalExamResultDto(
      result: _resultFromDrift(row),
      syncMetadata: SyncMetadata(
        id: row.id,
        userId: row.userId,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        deletedAt: row.deletedAt,
        syncStatus: status,
      ),
    );
  }

  MedicalExam _fromDrift(
    db.MedicalExam exam,
    List<db.MedicalExamResult> results,
  ) => MedicalExam(
    id: exam.id,
    userId: exam.userId,
    performedAt: exam.performedAt,
    collectedAt: exam.collectedAt,
    receivedAt: exam.receivedAt,
    title: exam.title,
    examCategory: exam.category == null
        ? null
        : MedicalExamCategory.values.firstWhere(
            (item) => item.name == exam.category,
            orElse: () => MedicalExamCategory.other,
          ),
    laboratoryName: exam.laboratoryName,
    professionalName: exam.professionalName,
    requestProfessionalName: exam.requestProfessionalName,
    documentNumber: exam.documentNumber,
    notes: exam.notes,
    source: MedicalExamSource.values.firstWhere(
      (item) => item.name == exam.source,
      orElse: () => MedicalExamSource.unknown,
    ),
    sourceDocumentId: exam.sourceDocumentId,
    legacyAttachmentPath: exam.legacyAttachmentPath,
    results: results.map(_resultFromDrift).toList(growable: false),
    createdAt: exam.createdAt,
    updatedAt: exam.updatedAt,
    deletedAt: exam.deletedAt,
    syncStatus: SyncStatus.fromName(exam.syncStatus),
  );

  MedicalExamResult _resultFromDrift(db.MedicalExamResult row) =>
      MedicalExamResult(
        id: row.id,
        medicalExamId: row.medicalExamId,
        canonicalCode: row.canonicalCode,
        canonicalName: row.canonicalName,
        displayName: row.displayName,
        normalizedName: row.normalizedName,
        category: row.category == null
            ? null
            : MedicalExamCategory.values.firstWhere(
                (item) => item.name == row.category,
                orElse: () => MedicalExamCategory.other,
              ),
        valueType: MedicalExamValueType.values.firstWhere(
          (item) => item.name == row.valueType,
          orElse: () => MedicalExamValueType.unknown,
        ),
        numericValue: row.numericValue,
        textValue: row.textValue,
        booleanValue: row.booleanValue,
        qualitativeValue: row.qualitativeValue,
        unit: row.unit,
        normalizedUnit: row.normalizedUnit,
        referenceRangeText: row.referenceRangeText,
        referenceMin: row.referenceMin,
        referenceMax: row.referenceMax,
        referenceComparator: row.referenceComparator == null
            ? null
            : ReferenceComparator.values.firstWhere(
                (item) => item.name == row.referenceComparator,
                orElse: () => ReferenceComparator.textual,
              ),
        referenceContext: row.referenceContext,
        status: row.status,
        method: row.method,
        specimen: row.specimen,
        notes: row.notes,
        originalText: row.originalText,
        source: MedicalExamResultSource.values.firstWhere(
          (item) => item.name == row.source,
          orElse: () => MedicalExamResultSource.unknown,
        ),
        confidence: row.confidence,
        sortOrder: row.sortOrder,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        deletedAt: row.deletedAt,
        syncStatus: SyncStatus.fromName(row.syncStatus),
      );

  db.MedicalExamsCompanion _examCompanion(
    MedicalExam exam,
    SyncMetadata metadata,
  ) => db.MedicalExamsCompanion.insert(
    id: exam.id,
    userId: userId,
    performedAt: exam.performedAt,
    collectedAt: Value(exam.collectedAt),
    receivedAt: Value(exam.receivedAt),
    title: Value(exam.title),
    category: Value(exam.examCategory?.name),
    laboratoryName: Value(exam.laboratoryName),
    professionalName: Value(exam.professionalName),
    requestProfessionalName: Value(exam.requestProfessionalName),
    documentNumber: Value(exam.documentNumber),
    notes: Value(exam.notes),
    source: exam.source.name,
    sourceDocumentId: Value(exam.sourceDocumentId),
    legacyAttachmentPath: Value(exam.legacyAttachmentPath),
    createdAt: metadata.createdAt,
    updatedAt: metadata.updatedAt,
    deletedAt: Value(metadata.deletedAt),
    syncStatus: metadata.syncStatus.name,
  );

  db.MedicalExamResultsCompanion _resultCompanion(
    MedicalExamResult result,
    SyncMetadata metadata,
  ) => db.MedicalExamResultsCompanion.insert(
    id: result.id,
    userId: userId,
    medicalExamId: result.medicalExamId,
    canonicalCode: Value(result.canonicalCode),
    canonicalName: result.canonicalName,
    displayName: result.displayName,
    normalizedName: result.normalizedName,
    category: Value(result.category?.name),
    valueType: result.valueType.name,
    numericValue: Value(result.numericValue),
    textValue: Value(result.textValue),
    booleanValue: Value(result.booleanValue),
    qualitativeValue: Value(result.qualitativeValue),
    unit: Value(result.unit),
    normalizedUnit: Value(result.normalizedUnit),
    referenceRangeText: Value(result.referenceRangeText),
    referenceMin: Value(result.referenceMin),
    referenceMax: Value(result.referenceMax),
    referenceComparator: Value(result.referenceComparator?.name),
    referenceContext: Value(result.referenceContext),
    status: Value(result.status),
    method: Value(result.method),
    specimen: Value(result.specimen),
    notes: Value(result.notes),
    originalText: Value(result.originalText),
    source: result.source.name,
    confidence: Value(result.confidence),
    sortOrder: result.sortOrder,
    createdAt: metadata.createdAt,
    updatedAt: metadata.updatedAt,
    deletedAt: Value(metadata.deletedAt),
    syncStatus: metadata.syncStatus.name,
  );

  db.MedicalExamsCompanion _syncCopyExam(
    db.MedicalExam row, {
    required SyncStatus status,
    required String? previousStatus,
    required int attempts,
    required String? error,
  }) => db.MedicalExamsCompanion(
    id: Value(row.id),
    userId: Value(row.userId),
    performedAt: Value(row.performedAt),
    collectedAt: Value(row.collectedAt),
    receivedAt: Value(row.receivedAt),
    title: Value(row.title),
    category: Value(row.category),
    laboratoryName: Value(row.laboratoryName),
    professionalName: Value(row.professionalName),
    requestProfessionalName: Value(row.requestProfessionalName),
    documentNumber: Value(row.documentNumber),
    notes: Value(row.notes),
    source: Value(row.source),
    sourceDocumentId: Value(row.sourceDocumentId),
    legacyAttachmentPath: Value(row.legacyAttachmentPath),
    createdAt: Value(row.createdAt),
    updatedAt: Value(row.updatedAt),
    deletedAt: Value(row.deletedAt),
    syncStatus: Value(status.name),
    previousSyncStatus: Value(previousStatus),
    syncAttempts: Value(attempts),
    lastSyncError: Value(error),
  );

  db.MedicalExamResultsCompanion _syncCopyResult(
    db.MedicalExamResult row, {
    required SyncStatus status,
    required String? previousStatus,
    required int attempts,
    required String? error,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) => db.MedicalExamResultsCompanion(
    id: Value(row.id),
    userId: Value(row.userId),
    medicalExamId: Value(row.medicalExamId),
    canonicalCode: Value(row.canonicalCode),
    canonicalName: Value(row.canonicalName),
    displayName: Value(row.displayName),
    normalizedName: Value(row.normalizedName),
    category: Value(row.category),
    valueType: Value(row.valueType),
    numericValue: Value(row.numericValue),
    textValue: Value(row.textValue),
    booleanValue: Value(row.booleanValue),
    qualitativeValue: Value(row.qualitativeValue),
    unit: Value(row.unit),
    normalizedUnit: Value(row.normalizedUnit),
    referenceRangeText: Value(row.referenceRangeText),
    referenceMin: Value(row.referenceMin),
    referenceMax: Value(row.referenceMax),
    referenceComparator: Value(row.referenceComparator),
    referenceContext: Value(row.referenceContext),
    status: Value(row.status),
    method: Value(row.method),
    specimen: Value(row.specimen),
    notes: Value(row.notes),
    originalText: Value(row.originalText),
    source: Value(row.source),
    confidence: Value(row.confidence),
    sortOrder: Value(row.sortOrder),
    createdAt: Value(row.createdAt),
    updatedAt: Value(updatedAt ?? row.updatedAt),
    deletedAt: Value(deletedAt ?? row.deletedAt),
    syncStatus: Value(status.name),
    previousSyncStatus: Value(previousStatus),
    syncAttempts: Value(attempts),
    lastSyncError: Value(error),
  );
}
