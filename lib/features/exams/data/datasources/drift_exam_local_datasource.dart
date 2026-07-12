import 'package:drift/drift.dart' show Value;
import '../../../../core/database/drift/app_database.dart';
import '../../../../core/database/drift/daos/exam_dao.dart';
import '../../../../core/database/drift/migrations/exam_legacy_service.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/sync/sync.dart';
import '../dtos/exam_dto.dart';

class DriftExamLocalDatasource {
  const DriftExamLocalDatasource({
    required ExamDao dao,
    required ClockService clock,
    required this.userId,
  }) : _dao = dao,
       _clock = clock;
  final ExamDao _dao;
  final ClockService _clock;
  final String userId;
  bool get canSync => userId != anonymousExamUserId;
  Future<List<ExamDto>> getAll() async =>
      (await _dao.getActiveByUser(userId)).map(_fromDrift).toList();
  Future<ExamDto?> getById(String id) async {
    final r = await _dao.getByUserAndId(userId, id);
    return r == null ? null : _fromDrift(r);
  }

  Future<void> save(ExamDto value) async {
    final previous = await getById(value.id);
    final dto = ExamDto.fromEntity(
      value.toEntity(),
      now: _clock.now(),
      previousMetadata: previous?.syncMetadata.copyWith(userId: userId),
    );
    await _dao.upsert(_companion(dto));
  }

  Future<void> delete(String id) async {
    final value = await getById(id);
    if (value == null) return;
    final now = _clock.now();
    await _dao.upsert(
      _companion(
        ExamDto(
          id: value.id,
          name: value.name,
          examDate: value.examDate,
          laboratory: value.laboratory,
          notes: value.notes,
          attachmentPath: value.attachmentPath,
          syncMetadata: value.syncMetadata.copyWith(
            updatedAt: now,
            deletedAt: now,
            syncStatus: SyncStatus.pendingDelete,
          ),
        ),
      ),
    );
  }

  Future<List<ExamDto>> pendingSync() async => canSync
      ? (await _dao.getPendingForSync(userId)).map(_pending).toList()
      : const [];
  Future<ExamDto?> pendingById(String id) async {
    if (!canSync) return null;
    final r = await _dao.getByUserAndId(userId, id);
    return r == null || r.syncStatus == 'synced' ? null : _pending(r);
  }

  Future<void> applyRemote(ExamDto remote) async {
    if (!canSync || remote.syncMetadata.userId != userId) return;
    final local = await getById(remote.id);
    if (local != null &&
        !remote.syncMetadata.updatedAt.isAfter(local.syncMetadata.updatedAt)) {
      return;
    }
    await _dao.upsert(_companion(remote));
  }

  Future<void> applyRemoteAndMarkSynced(ExamDto remote) =>
      _dao.inTransaction(() async {
        await applyRemote(remote);
        await markSynced(remote.id);
      });
  Future<void> markSynced(String id) async {
    final r = await _dao.getByUserAndId(userId, id);
    if (r != null) {
      await _dao.upsert(_sync(r, SyncStatus.synced, 0));
    }
  }

  Future<void> markFailed(String id, String error) async {
    final r = await _dao.getByUserAndId(userId, id);
    if (r != null) {
      await _dao.upsert(
        _sync(
          r,
          SyncStatus.failed,
          r.syncAttempts + 1,
          previous: r.previousSyncStatus ?? r.syncStatus,
          error: error,
        ),
      );
    }
  }

  Future<DateTime?> getLastPullAt(String key) =>
      _dao.getLastPullAt(userId, key);
  Future<void> saveCursor(String key, DateTime at) =>
      _dao.saveCursor(userId, key, at);
  ExamDto _pending(ExamRecord r) {
    final dto = _fromDrift(r);
    return r.syncStatus == 'failed'
        ? ExamDto(
            id: dto.id,
            name: dto.name,
            examDate: dto.examDate,
            laboratory: dto.laboratory,
            notes: dto.notes,
            attachmentPath: dto.attachmentPath,
            syncMetadata: dto.syncMetadata.copyWith(
              syncStatus: SyncStatus.fromName(r.previousSyncStatus),
            ),
          )
        : dto;
  }

  ExamDto _fromDrift(ExamRecord r) => ExamDto(
    id: r.id,
    name: r.name,
    examDate: r.examDate,
    laboratory: r.laboratory,
    notes: r.notes,
    attachmentPath: r.attachmentPath,
    syncMetadata: SyncMetadata(
      id: r.id,
      userId: r.userId,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
      deletedAt: r.deletedAt,
      syncStatus: SyncStatus.fromName(r.syncStatus),
    ),
  );
  ExamRecordsCompanion _companion(ExamDto d) => ExamRecordsCompanion.insert(
    id: d.id,
    userId: userId,
    name: d.name,
    examDate: d.examDate,
    laboratory: Value(d.laboratory),
    notes: Value(d.notes),
    attachmentPath: Value(d.attachmentPath),
    createdAt: d.syncMetadata.createdAt,
    updatedAt: d.syncMetadata.updatedAt,
    deletedAt: Value(d.syncMetadata.deletedAt),
    syncStatus: d.syncMetadata.syncStatus.name,
  );
  ExamRecordsCompanion _sync(
    ExamRecord r,
    SyncStatus s,
    int attempts, {
    String? previous,
    String? error,
  }) => ExamRecordsCompanion(
    id: Value(r.id),
    userId: Value(r.userId),
    name: Value(r.name),
    examDate: Value(r.examDate),
    laboratory: Value(r.laboratory),
    notes: Value(r.notes),
    attachmentPath: Value(r.attachmentPath),
    createdAt: Value(r.createdAt),
    updatedAt: Value(r.updatedAt),
    deletedAt: Value(r.deletedAt),
    syncStatus: Value(s.name),
    previousSyncStatus: Value(previous),
    syncAttempts: Value(attempts),
    lastSyncError: Value(error),
  );
}
