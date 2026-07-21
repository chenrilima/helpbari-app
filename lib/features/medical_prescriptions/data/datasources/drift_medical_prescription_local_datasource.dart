import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../../../core/database/drift/app_database.dart' as db;
import '../../../../core/database/drift/daos/medical_prescription_dao.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/sync/sync.dart';
import '../../domain/entities/entities.dart';
import '../dtos/medical_prescription_dto.dart';

class DriftMedicalPrescriptionLocalDatasource {
  const DriftMedicalPrescriptionLocalDatasource({
    required MedicalPrescriptionDao dao,
    required ClockService clock,
    required this.userId,
  }) : _dao = dao,
       _clock = clock;

  final MedicalPrescriptionDao _dao;
  final ClockService _clock;
  final String userId;

  Stream<List<MedicalPrescription>> watchAll() =>
      _dao.watchActive(userId).asyncMap(_fromRows);

  Future<List<MedicalPrescription>> getAll() async =>
      _fromRows(await _dao.getActive(userId));

  Future<List<MedicalPrescription>> getLimited({required int limit}) async =>
      _fromRows(await _dao.getActiveLimited(userId, limit: limit));

  Future<int> countRequiringReview() => _dao.countRequiringReview(userId);

  Future<MedicalPrescription?> getById(String id) async {
    final row = await _dao.getById(userId, id);
    if (row == null || row.deletedAt != null) return null;
    return _fromRow(row, await _dao.getItems(userId, id));
  }

  Future<void> save(MedicalPrescription prescription) async {
    if (prescription.userId != userId) {
      throw StateError('Prescription user mismatch.');
    }
    final existing = await _dao.getById(userId, prescription.id);
    final now = _clock.now().toUtc();
    final createdAt = existing?.createdAt ?? prescription.createdAt;
    final nextStatus = existing == null
        ? SyncStatus.pendingCreate
        : SyncStatus.pendingUpdate;
    final currentItems = await _dao.getItems(
      userId,
      prescription.id,
      includeDeleted: true,
    );
    final nextIds = prescription.items.map((item) => item.id).toSet();
    await _dao.inTransaction(() async {
      await _dao.upsertPrescription(
        _prescriptionCompanion(
          prescription.copyWith(updatedAt: now, syncStatus: nextStatus),
          createdAt: createdAt,
          updatedAt: now,
          syncStatus: nextStatus,
        ),
      );
      for (final item in prescription.items) {
        final old = currentItems.where((row) => row.id == item.id).firstOrNull;
        await _dao.upsertItem(
          _itemCompanion(
            item,
            createdAt: old?.createdAt ?? item.createdAt,
            updatedAt: now,
            syncStatus: old == null
                ? SyncStatus.pendingCreate
                : SyncStatus.pendingUpdate,
          ),
        );
      }
      for (final old in currentItems.where(
        (row) => !nextIds.contains(row.id),
      )) {
        await _dao.upsertItem(
          _copyItem(
            old,
            updatedAt: now,
            deletedAt: now,
            syncStatus: SyncStatus.pendingDelete,
          ),
        );
      }
    });
  }

  Future<void> delete(String id) async {
    final row = await _dao.getById(userId, id);
    if (row == null) return;
    final now = _clock.now().toUtc();
    final items = await _dao.getItems(userId, id, includeDeleted: true);
    await _dao.inTransaction(() async {
      await _dao.upsertPrescription(
        _copyPrescription(
          row,
          updatedAt: now,
          deletedAt: now,
          syncStatus: SyncStatus.pendingDelete,
        ),
      );
      for (final item in items) {
        await _dao.upsertItem(
          _copyItem(
            item,
            updatedAt: now,
            deletedAt: now,
            syncStatus: SyncStatus.pendingDelete,
          ),
        );
      }
    });
  }

  Future<List<MedicalPrescriptionDto>> pendingSync() async =>
      _dtos(await _dao.getPending(userId), includeDeleted: true);

  Future<MedicalPrescriptionDto?> pendingById(String id) async {
    final row = await _dao.getById(userId, id);
    if (row == null) return null;
    return _dto(row, includeDeleted: true);
  }

  Future<void> applyRemote(MedicalPrescriptionDto dto) async {
    if (dto.prescription.userId != userId) return;
    final local = await _dao.getById(userId, dto.prescription.id);
    if (local != null && !dto.metadata.updatedAt.isAfter(local.updatedAt)) {
      return;
    }
    await _dao.inTransaction(() async {
      await _dao.upsertPrescription(
        _prescriptionCompanion(
          dto.prescription,
          createdAt: dto.metadata.createdAt,
          updatedAt: dto.metadata.updatedAt,
          deletedAt: dto.metadata.deletedAt,
          syncStatus: SyncStatus.synced,
        ),
      );
      for (final item in dto.prescription.items) {
        await _dao.upsertItem(
          _itemCompanion(
            item,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
            deletedAt: item.deletedAt,
            syncStatus: SyncStatus.synced,
          ),
        );
      }
    });
  }

  Future<void> markSynced(String id) async {
    final row = await _dao.getById(userId, id);
    if (row == null) return;
    final items = await _dao.getItems(userId, id, includeDeleted: true);
    await _dao.inTransaction(() async {
      await _dao.upsertPrescription(
        _copyPrescription(row, syncStatus: SyncStatus.synced),
      );
      for (final item in items) {
        await _dao.upsertItem(_copyItem(item, syncStatus: SyncStatus.synced));
      }
    });
  }

  Future<void> markFailed(String id, String message) async {
    final row = await _dao.getById(userId, id);
    if (row == null) return;
    await _dao.upsertPrescription(
      _copyPrescription(row, syncStatus: SyncStatus.failed, error: message),
    );
  }

  Future<DateTime?> getLastPullAt(String key) =>
      _dao.getLastPullAt(userId, key);
  Future<void> saveCursor(String key, DateTime at) =>
      _dao.saveCursor(userId, key, at);

  Future<List<MedicalPrescription>> _fromRows(
    List<db.MedicalPrescriptionRecord> rows,
  ) async {
    final items = await _dao.getActiveItemsForPrescriptions(
      userId,
      rows.map((row) => row.id),
    );
    final byPrescription = <String, List<db.MedicalPrescriptionItemRecord>>{};
    for (final item in items) {
      byPrescription.putIfAbsent(item.prescriptionId, () => []).add(item);
    }
    return [
      for (final row in rows) _fromRow(row, byPrescription[row.id] ?? const []),
    ];
  }

  Future<List<MedicalPrescriptionDto>> _dtos(
    List<db.MedicalPrescriptionRecord> rows, {
    required bool includeDeleted,
  }) async {
    final values = <MedicalPrescriptionDto>[];
    for (final row in rows) {
      values.add(await _dto(row, includeDeleted: includeDeleted));
    }
    return values;
  }

  Future<MedicalPrescriptionDto> _dto(
    db.MedicalPrescriptionRecord row, {
    required bool includeDeleted,
  }) async {
    final entity = _fromRow(
      row,
      await _dao.getItems(userId, row.id, includeDeleted: includeDeleted),
    );
    final status = row.syncStatus == SyncStatus.failed.name
        ? SyncStatus.fromName(row.previousSyncStatus)
        : SyncStatus.fromName(row.syncStatus);
    return MedicalPrescriptionDto(
      prescription: entity.copyWith(syncStatus: status),
      metadata: SyncMetadata(
        id: row.id,
        userId: row.userId,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        deletedAt: row.deletedAt,
        syncStatus: status,
      ),
    );
  }

  MedicalPrescription _fromRow(
    db.MedicalPrescriptionRecord row,
    List<db.MedicalPrescriptionItemRecord> items,
  ) => MedicalPrescription(
    id: row.id,
    userId: row.userId,
    professionalName: row.professionalName,
    professionalSpecialty: row.professionalSpecialty,
    professionalRegistration: row.professionalRegistration,
    prescribedAt: row.prescribedAt,
    validUntil: row.validUntil,
    notes: row.notes,
    sourceDocumentId: row.sourceDocumentId,
    status: MedicalPrescriptionStatus.values.byName(row.status),
    items: items.map(_itemFromRow).toList(growable: false),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
    syncStatus: SyncStatus.fromName(row.syncStatus),
  );

  MedicalPrescriptionItem _itemFromRow(
    db.MedicalPrescriptionItemRecord row,
  ) => MedicalPrescriptionItem(
    id: row.id,
    prescriptionId: row.prescriptionId,
    userId: row.userId,
    itemType: PrescriptionItemType.values.byName(row.itemType),
    name: row.name,
    dosageValue: row.dosageValue,
    dosageUnit: row.dosageUnit,
    route: row.route,
    frequencyType: row.frequencyType == null
        ? null
        : PrescriptionFrequencyType.values.byName(row.frequencyType!),
    frequencyValue: row.frequencyValue,
    frequencyUnit: row.frequencyUnit,
    scheduleTimes: (jsonDecode(row.scheduleTimesJson) as List).cast<String>(),
    daysOfWeek: (jsonDecode(row.daysOfWeekJson) as List).cast<int>(),
    intervalDays: row.intervalDays,
    startDate: row.startDate,
    endDate: row.endDate,
    durationValue: row.durationValue,
    durationUnit: row.durationUnit,
    instructions: row.instructions,
    asNeeded: row.asNeeded,
    notes: row.notes,
    confidence: row.confidence,
    fieldConfidences: (jsonDecode(row.fieldConfidencesJson) as Map).map(
      (key, value) => MapEntry(key as String, (value as num).toDouble()),
    ),
    provenance: (jsonDecode(row.provenanceJson) as Map).cast<String, String>(),
    reviewStatus: PrescriptionReviewStatus.values.byName(row.reviewStatus),
    linkedMedicationId: row.linkedMedicationId,
    linkedVitaminId: row.linkedVitaminId,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    deletedAt: row.deletedAt,
    syncStatus: SyncStatus.fromName(row.syncStatus),
  );

  db.MedicalPrescriptionRecordsCompanion _prescriptionCompanion(
    MedicalPrescription value, {
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
    required SyncStatus syncStatus,
  }) => db.MedicalPrescriptionRecordsCompanion.insert(
    id: value.id,
    userId: userId,
    professionalName: Value(value.professionalName),
    professionalSpecialty: Value(value.professionalSpecialty),
    professionalRegistration: Value(value.professionalRegistration),
    prescribedAt: value.prescribedAt,
    validUntil: Value(value.validUntil),
    notes: Value(value.notes),
    sourceDocumentId: Value(value.sourceDocumentId),
    status: value.status.name,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: Value(deletedAt ?? value.deletedAt),
    syncStatus: syncStatus.name,
  );

  db.MedicalPrescriptionItemRecordsCompanion _itemCompanion(
    MedicalPrescriptionItem value, {
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
    required SyncStatus syncStatus,
  }) => db.MedicalPrescriptionItemRecordsCompanion.insert(
    id: value.id,
    prescriptionId: value.prescriptionId,
    userId: userId,
    itemType: value.itemType.name,
    name: value.name,
    dosageValue: Value(value.dosageValue),
    dosageUnit: Value(value.dosageUnit),
    route: Value(value.route),
    frequencyType: Value(value.frequencyType?.name),
    frequencyValue: Value(value.frequencyValue),
    frequencyUnit: Value(value.frequencyUnit),
    scheduleTimesJson: Value(jsonEncode(value.scheduleTimes)),
    daysOfWeekJson: Value(jsonEncode(value.daysOfWeek)),
    intervalDays: Value(value.intervalDays),
    startDate: Value(value.startDate),
    endDate: Value(value.endDate),
    durationValue: Value(value.durationValue),
    durationUnit: Value(value.durationUnit),
    instructions: Value(value.instructions),
    asNeeded: Value(value.asNeeded),
    notes: Value(value.notes),
    confidence: Value(value.confidence),
    fieldConfidencesJson: Value(jsonEncode(value.fieldConfidences)),
    provenanceJson: Value(jsonEncode(value.provenance)),
    reviewStatus: value.reviewStatus.name,
    linkedMedicationId: Value(value.linkedMedicationId),
    linkedVitaminId: Value(value.linkedVitaminId),
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: Value(deletedAt ?? value.deletedAt),
    syncStatus: syncStatus.name,
  );

  db.MedicalPrescriptionRecordsCompanion _copyPrescription(
    db.MedicalPrescriptionRecord row, {
    DateTime? updatedAt,
    DateTime? deletedAt,
    required SyncStatus syncStatus,
    String? error,
  }) => db.MedicalPrescriptionRecordsCompanion(
    id: Value(row.id),
    userId: Value(row.userId),
    professionalName: Value(row.professionalName),
    professionalSpecialty: Value(row.professionalSpecialty),
    professionalRegistration: Value(row.professionalRegistration),
    prescribedAt: Value(row.prescribedAt),
    validUntil: Value(row.validUntil),
    notes: Value(row.notes),
    sourceDocumentId: Value(row.sourceDocumentId),
    status: Value(row.status),
    createdAt: Value(row.createdAt),
    updatedAt: Value(updatedAt ?? row.updatedAt),
    deletedAt: Value(deletedAt ?? row.deletedAt),
    syncStatus: Value(syncStatus.name),
    previousSyncStatus: Value(error == null ? null : row.syncStatus),
    syncAttempts: Value(error == null ? 0 : row.syncAttempts + 1),
    lastSyncError: Value(error),
  );

  db.MedicalPrescriptionItemRecordsCompanion _copyItem(
    db.MedicalPrescriptionItemRecord row, {
    DateTime? updatedAt,
    DateTime? deletedAt,
    required SyncStatus syncStatus,
  }) => db.MedicalPrescriptionItemRecordsCompanion(
    id: Value(row.id),
    prescriptionId: Value(row.prescriptionId),
    userId: Value(row.userId),
    itemType: Value(row.itemType),
    name: Value(row.name),
    dosageValue: Value(row.dosageValue),
    dosageUnit: Value(row.dosageUnit),
    route: Value(row.route),
    frequencyType: Value(row.frequencyType),
    frequencyValue: Value(row.frequencyValue),
    frequencyUnit: Value(row.frequencyUnit),
    scheduleTimesJson: Value(row.scheduleTimesJson),
    daysOfWeekJson: Value(row.daysOfWeekJson),
    intervalDays: Value(row.intervalDays),
    startDate: Value(row.startDate),
    endDate: Value(row.endDate),
    durationValue: Value(row.durationValue),
    durationUnit: Value(row.durationUnit),
    instructions: Value(row.instructions),
    asNeeded: Value(row.asNeeded),
    notes: Value(row.notes),
    confidence: Value(row.confidence),
    fieldConfidencesJson: Value(row.fieldConfidencesJson),
    provenanceJson: Value(row.provenanceJson),
    reviewStatus: Value(row.reviewStatus),
    linkedMedicationId: Value(row.linkedMedicationId),
    linkedVitaminId: Value(row.linkedVitaminId),
    createdAt: Value(row.createdAt),
    updatedAt: Value(updatedAt ?? row.updatedAt),
    deletedAt: Value(deletedAt ?? row.deletedAt),
    syncStatus: Value(syncStatus.name),
    previousSyncStatus: const Value(null),
    syncAttempts: const Value(0),
    lastSyncError: const Value(null),
  );
}
