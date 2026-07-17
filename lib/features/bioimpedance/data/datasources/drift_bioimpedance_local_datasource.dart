import 'package:drift/drift.dart' show Value;

import '../../../../core/database/drift/app_database.dart' as db;
import '../../../../core/database/drift/daos/bioimpedance_dao.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/sync/sync.dart';
import '../../domain/entities/bioimpedance_record.dart';
import '../dtos/bioimpedance_record_dto.dart';

const anonymousBioimpedanceUserId = 'anonymous';

class DriftBioimpedanceLocalDatasource {
  const DriftBioimpedanceLocalDatasource({
    required BioimpedanceDao dao,
    required ClockService clock,
    required this.userId,
  }) : _dao = dao,
       _clock = clock;

  final BioimpedanceDao _dao;
  final ClockService _clock;
  final String userId;
  bool get canSync => userId != anonymousBioimpedanceUserId;

  Future<List<BioimpedanceRecord>> getHistory() async =>
      (await _dao.getActiveByUser(userId)).map(_fromDrift).toList();

  Future<BioimpedanceRecord?> getById(String id) async {
    final row = await _dao.getByUserAndId(userId, id);
    return row == null ? null : _fromDrift(row);
  }

  Future<void> save(BioimpedanceRecord record) async {
    if (!record.hasAnyMeasurement) {
      throw const FormatException('Informe ao menos uma medida corporal.');
    }
    final previous = await _pendingById(record.id);
    final dto = BioimpedanceRecordDto.fromEntity(
      record,
      now: _clock.now(),
      previousMetadata: previous?.syncMetadata,
    );
    await _dao.upsert(_companion(dto.record, dto.syncMetadata));
  }

  Future<void> delete(String id) async {
    final previous = await _pendingById(id);
    if (previous == null) return;
    final now = _clock.now();
    await _dao.upsert(
      _companion(
        previous.record.copyWith(deletedAt: now, updatedAt: now),
        previous.syncMetadata.copyWith(
          updatedAt: now,
          deletedAt: now,
          syncStatus: SyncStatus.pendingDelete,
        ),
      ),
    );
  }

  Future<List<BioimpedanceRecordDto>> pendingSync() async => canSync
      ? (await _dao.getPendingForSync(userId)).map(_pendingDto).toList()
      : const [];

  Future<BioimpedanceRecordDto?> pendingById(String id) => _pendingById(id);

  Future<void> applyRemote(BioimpedanceRecordDto remote) async {
    if (!canSync || remote.syncMetadata.userId != userId) return;
    final local = await _pendingById(remote.record.id);
    if (local != null &&
        !remote.syncMetadata.updatedAt.isAfter(local.syncMetadata.updatedAt)) {
      return;
    }
    await _dao.upsert(_companion(remote.record, remote.syncMetadata));
  }

  Future<void> applyRemoteAndMarkSynced(BioimpedanceRecordDto remote) =>
      _dao.inTransaction(() async {
        await applyRemote(remote);
        await markSynced(remote.record.id);
      });

  Future<void> markSynced(String id) => _updateSync(id, SyncStatus.synced);

  Future<void> markFailed(String id, String message) async {
    final row = await _dao.getByUserAndId(userId, id);
    if (row == null) return;
    await _dao.upsert(
      _syncCopy(
        row,
        status: SyncStatus.failed,
        previousStatus: row.previousSyncStatus ?? row.syncStatus,
        attempts: row.syncAttempts + 1,
        error: message,
      ),
    );
  }

  Future<DateTime?> getLastPullAt(String key) =>
      _dao.getLastPullAt(userId, key);
  Future<void> saveCursor(String key, DateTime at) =>
      _dao.saveCursor(userId, key, at);

  Future<BioimpedanceRecordDto?> _pendingById(String id) async {
    final row = await _dao.getByUserAndId(userId, id);
    if (row == null) return null;
    return _pendingDto(row);
  }

  Future<void> _updateSync(String id, SyncStatus status) async {
    final row = await _dao.getByUserAndId(userId, id);
    if (row == null) return;
    await _dao.upsert(_syncCopy(row, status: status, attempts: 0));
  }

  BioimpedanceRecordDto _pendingDto(db.BioimpedanceRecord row) {
    final record = _fromDrift(row);
    final status = row.syncStatus == SyncStatus.failed.name
        ? SyncStatus.fromName(row.previousSyncStatus)
        : SyncStatus.fromName(row.syncStatus);
    return BioimpedanceRecordDto(
      record: record,
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

  BioimpedanceRecord _fromDrift(db.BioimpedanceRecord row) =>
      BioimpedanceRecord(
        id: row.id,
        userId: row.userId,
        measuredAt: row.measuredAt,
        weightKg: row.weightKg,
        muscleMassKg: row.muscleMassKg,
        bodyFatMassKg: row.bodyFatMassKg,
        bodyWaterPercentage: row.bodyWaterPercentage,
        bodyFatPercentage: row.bodyFatPercentage,
        skeletalMuscleMassKg: row.skeletalMuscleMassKg,
        leanBodyMassKg: row.leanBodyMassKg,
        fatFreeMassKg: row.fatFreeMassKg,
        visceralFatLevel: row.visceralFatLevel,
        visceralFatAreaCm2: row.visceralFatAreaCm2,
        subcutaneousFatPercentage: row.subcutaneousFatPercentage,
        proteinPercentage: row.proteinPercentage,
        mineralMassKg: row.mineralMassKg,
        boneMassKg: row.boneMassKg,
        bmi: row.bmi,
        basalMetabolicRateKcal: row.basalMetabolicRateKcal,
        metabolicAge: row.metabolicAge,
        waistHipRatio: row.waistHipRatio,
        waistCircumferenceCm: row.waistCircumferenceCm,
        hipCircumferenceCm: row.hipCircumferenceCm,
        bodyCellMassKg: row.bodyCellMassKg,
        intracellularWaterLiters: row.intracellularWaterLiters,
        extracellularWaterLiters: row.extracellularWaterLiters,
        totalBodyWaterLiters: row.totalBodyWaterLiters,
        phaseAngleDegrees: row.phaseAngleDegrees,
        bodyScore: row.bodyScore,
        recommendedWeightKg: row.recommendedWeightKg,
        weightControlKg: row.weightControlKg,
        fatControlKg: row.fatControlKg,
        muscleControlKg: row.muscleControlKg,
        deviceName: row.deviceName,
        clinicName: row.clinicName,
        professionalName: row.professionalName,
        notes: row.notes,
        sourceDocumentId: row.sourceDocumentId,
        source: BioimpedanceRecordSource.values.byName(row.source),
        additionalMetrics: BioimpedanceRecordDto.metricsFromJson(
          row.additionalMetricsJson,
        ),
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        deletedAt: row.deletedAt,
        syncStatus: SyncStatus.fromName(row.syncStatus),
      );

  db.BioimpedanceRecordsCompanion _companion(
    BioimpedanceRecord record,
    SyncMetadata metadata,
  ) => db.BioimpedanceRecordsCompanion.insert(
    id: record.id,
    userId: userId,
    measuredAt: record.measuredAt,
    weightKg: Value(record.weightKg),
    muscleMassKg: Value(record.muscleMassKg),
    bodyFatMassKg: Value(record.bodyFatMassKg),
    bodyWaterPercentage: Value(record.bodyWaterPercentage),
    bodyFatPercentage: Value(record.bodyFatPercentage),
    skeletalMuscleMassKg: Value(record.skeletalMuscleMassKg),
    leanBodyMassKg: Value(record.leanBodyMassKg),
    fatFreeMassKg: Value(record.fatFreeMassKg),
    visceralFatLevel: Value(record.visceralFatLevel),
    visceralFatAreaCm2: Value(record.visceralFatAreaCm2),
    subcutaneousFatPercentage: Value(record.subcutaneousFatPercentage),
    proteinPercentage: Value(record.proteinPercentage),
    mineralMassKg: Value(record.mineralMassKg),
    boneMassKg: Value(record.boneMassKg),
    bmi: Value(record.bmi),
    basalMetabolicRateKcal: Value(record.basalMetabolicRateKcal),
    metabolicAge: Value(record.metabolicAge),
    waistHipRatio: Value(record.waistHipRatio),
    waistCircumferenceCm: Value(record.waistCircumferenceCm),
    hipCircumferenceCm: Value(record.hipCircumferenceCm),
    bodyCellMassKg: Value(record.bodyCellMassKg),
    intracellularWaterLiters: Value(record.intracellularWaterLiters),
    extracellularWaterLiters: Value(record.extracellularWaterLiters),
    totalBodyWaterLiters: Value(record.totalBodyWaterLiters),
    phaseAngleDegrees: Value(record.phaseAngleDegrees),
    bodyScore: Value(record.bodyScore),
    recommendedWeightKg: Value(record.recommendedWeightKg),
    weightControlKg: Value(record.weightControlKg),
    fatControlKg: Value(record.fatControlKg),
    muscleControlKg: Value(record.muscleControlKg),
    deviceName: Value(record.deviceName),
    clinicName: Value(record.clinicName),
    professionalName: Value(record.professionalName),
    notes: Value(record.notes),
    sourceDocumentId: Value(record.sourceDocumentId),
    source: record.source.name,
    additionalMetricsJson: Value(
      BioimpedanceRecordDto.metricsToJson(record.additionalMetrics),
    ),
    createdAt: metadata.createdAt,
    updatedAt: metadata.updatedAt,
    deletedAt: Value(metadata.deletedAt),
    syncStatus: metadata.syncStatus.name,
  );

  db.BioimpedanceRecordsCompanion _syncCopy(
    db.BioimpedanceRecord row, {
    required SyncStatus status,
    String? previousStatus,
    required int attempts,
    String? error,
  }) => db.BioimpedanceRecordsCompanion(
    id: Value(row.id),
    userId: Value(row.userId),
    measuredAt: Value(row.measuredAt),
    weightKg: Value(row.weightKg),
    muscleMassKg: Value(row.muscleMassKg),
    bodyFatMassKg: Value(row.bodyFatMassKg),
    bodyWaterPercentage: Value(row.bodyWaterPercentage),
    bodyFatPercentage: Value(row.bodyFatPercentage),
    skeletalMuscleMassKg: Value(row.skeletalMuscleMassKg),
    leanBodyMassKg: Value(row.leanBodyMassKg),
    fatFreeMassKg: Value(row.fatFreeMassKg),
    visceralFatLevel: Value(row.visceralFatLevel),
    visceralFatAreaCm2: Value(row.visceralFatAreaCm2),
    subcutaneousFatPercentage: Value(row.subcutaneousFatPercentage),
    proteinPercentage: Value(row.proteinPercentage),
    mineralMassKg: Value(row.mineralMassKg),
    boneMassKg: Value(row.boneMassKg),
    bmi: Value(row.bmi),
    basalMetabolicRateKcal: Value(row.basalMetabolicRateKcal),
    metabolicAge: Value(row.metabolicAge),
    waistHipRatio: Value(row.waistHipRatio),
    waistCircumferenceCm: Value(row.waistCircumferenceCm),
    hipCircumferenceCm: Value(row.hipCircumferenceCm),
    bodyCellMassKg: Value(row.bodyCellMassKg),
    intracellularWaterLiters: Value(row.intracellularWaterLiters),
    extracellularWaterLiters: Value(row.extracellularWaterLiters),
    totalBodyWaterLiters: Value(row.totalBodyWaterLiters),
    phaseAngleDegrees: Value(row.phaseAngleDegrees),
    bodyScore: Value(row.bodyScore),
    recommendedWeightKg: Value(row.recommendedWeightKg),
    weightControlKg: Value(row.weightControlKg),
    fatControlKg: Value(row.fatControlKg),
    muscleControlKg: Value(row.muscleControlKg),
    deviceName: Value(row.deviceName),
    clinicName: Value(row.clinicName),
    professionalName: Value(row.professionalName),
    notes: Value(row.notes),
    sourceDocumentId: Value(row.sourceDocumentId),
    source: Value(row.source),
    additionalMetricsJson: Value(row.additionalMetricsJson),
    createdAt: Value(row.createdAt),
    updatedAt: Value(row.updatedAt),
    deletedAt: Value(row.deletedAt),
    syncStatus: Value(status.name),
    previousSyncStatus: Value(previousStatus),
    syncAttempts: Value(attempts),
    lastSyncError: Value(error),
  );
}
