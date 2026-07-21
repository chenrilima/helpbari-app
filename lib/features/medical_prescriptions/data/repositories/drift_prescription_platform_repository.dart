import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/drift/app_database.dart';
import '../../../../core/services/clock_service.dart';
import '../../../../core/sync/sync.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/prescription_platform_repository.dart';
import '../datasources/drift_medical_prescription_local_datasource.dart';
import '../dtos/medical_prescription_dto.dart';

class DriftPrescriptionPlatformRepository
    implements PrescriptionPlatformRepository {
  const DriftPrescriptionPlatformRepository({
    required this.database,
    required this.prescriptions,
    required this.clock,
    required this.userId,
    required this.timeZone,
    this.uuid = const Uuid(),
  });

  final AppDatabase database;
  final DriftMedicalPrescriptionLocalDatasource prescriptions;
  final ClockService clock;
  final String userId;
  final String timeZone;
  final Uuid uuid;

  @override
  Future<PrescriptionVersion> createDraftVersion({
    required MedicalPrescription snapshot,
    String? sourceProcessingId,
  }) async {
    _requireUser(snapshot.userId);
    final previous = await history(snapshot.id);
    final now = clock.now().toUtc();
    final version = PrescriptionVersion(
      id: uuid.v4(),
      prescriptionId: snapshot.id,
      userId: userId,
      revision: previous.isEmpty ? 1 : previous.first.revision + 1,
      status: PrescriptionVersionStatus.draft,
      snapshot: snapshot,
      sourceProcessingId: sourceProcessingId,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pendingCreate,
    );
    await database
        .into(database.prescriptionVersionRecords)
        .insert(_versionCompanion(version));
    return version;
  }

  @override
  Future<PrescriptionVersion> submitForReview(String versionId) async {
    final current = await _version(versionId);
    if (current.status != PrescriptionVersionStatus.draft) {
      throw StateError('Only a draft prescription version can be submitted.');
    }
    final now = clock.now().toUtc();
    await _updateVersion(
      current,
      status: PrescriptionVersionStatus.requiresReview,
      submittedAt: now,
      updatedAt: now,
    );
    return _version(versionId);
  }

  @override
  Future<PrescriptionVersion> confirmVersion({
    required String versionId,
    required String actor,
    required Map<String, String> fieldDecisions,
  }) async {
    final current = await _version(versionId);
    if (current.status != PrescriptionVersionStatus.requiresReview) {
      throw StateError('Prescription version must be reviewed first.');
    }
    _validateForConfirmation(current.snapshot);
    final now = clock.now().toUtc();
    await database.transaction(() async {
      await _updateVersion(
        current,
        status: PrescriptionVersionStatus.confirmed,
        confirmedAt: now,
        updatedAt: now,
      );
      await database
          .into(database.prescriptionReviewRecords)
          .insert(
            PrescriptionReviewRecordsCompanion.insert(
              id: uuid.v4(),
              userId: userId,
              prescriptionId: current.prescriptionId,
              versionId: current.id,
              decision: PrescriptionReviewDecision.confirmed.name,
              actor: actor,
              fieldDecisionsJson: jsonEncode(fieldDecisions),
              createdAt: now,
              updatedAt: now,
              syncStatus: SyncStatus.pendingCreate.name,
            ),
          );
      await prescriptions.save(
        current.snapshot.copyWith(
          status: MedicalPrescriptionStatus.confirmed,
          updatedAt: now,
          syncStatus: SyncStatus.pendingUpdate,
        ),
      );
    });
    return _version(versionId);
  }

  @override
  Future<List<PrescriptionVersion>> history(String prescriptionId) async {
    final rows =
        await (database.select(database.prescriptionVersionRecords)
              ..where(
                (row) =>
                    row.userId.equals(userId) &
                    row.prescriptionId.equals(prescriptionId) &
                    row.deletedAt.isNull(),
              )
              ..orderBy([(row) => OrderingTerm.desc(row.revision)]))
            .get();
    return rows.map(_versionFromRow).toList(growable: false);
  }

  @override
  Future<List<TreatmentProposal>> createProposals(String versionId) async {
    final version = await _version(versionId);
    if (version.status != PrescriptionVersionStatus.confirmed) {
      throw StateError(
        'Only a confirmed prescription version can propose treatment.',
      );
    }
    final existing = await proposals(version.prescriptionId);
    final existingItemIds = existing
        .where((value) => value.prescriptionVersionId == versionId)
        .map((value) => value.prescriptionItemId)
        .toSet();
    final now = clock.now().toUtc();
    for (final item in version.snapshot.activeItems) {
      if (existingItemIds.contains(item.id)) continue;
      final draft = _treatmentDraft(item, version.snapshot);
      await database
          .into(database.treatmentProposalRecords)
          .insert(
            TreatmentProposalRecordsCompanion.insert(
              id: uuid.v4(),
              userId: userId,
              prescriptionId: version.prescriptionId,
              prescriptionVersionId: version.id,
              prescriptionItemId: item.id,
              decision: TreatmentProposalDecision.pending.name,
              draftJson: jsonEncode(draft),
              createdAt: now,
              updatedAt: now,
              syncStatus: SyncStatus.pendingCreate.name,
            ),
          );
    }
    return proposals(version.prescriptionId);
  }

  @override
  Future<List<TreatmentProposal>> proposals(String prescriptionId) async {
    final rows =
        await (database.select(database.treatmentProposalRecords)
              ..where(
                (row) =>
                    row.userId.equals(userId) &
                    row.prescriptionId.equals(prescriptionId) &
                    row.deletedAt.isNull(),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
            .get();
    return rows.map(_proposalFromRow).toList(growable: false);
  }

  @override
  Future<PrescriptionRoutineLink> confirmProposal({
    required String proposalId,
    required TreatmentProposalDecision decision,
    String? targetRoutineId,
  }) async {
    if (decision == TreatmentProposalDecision.pending ||
        decision == TreatmentProposalDecision.dismissed) {
      throw ArgumentError.value(decision, 'decision');
    }
    final row =
        await (database.select(database.treatmentProposalRecords)..where(
              (value) =>
                  value.userId.equals(userId) & value.id.equals(proposalId),
            ))
            .getSingleOrNull();
    if (row == null || row.decision != TreatmentProposalDecision.pending.name) {
      throw StateError('Treatment proposal is not pending.');
    }
    final draft = Map<String, dynamic>.from(jsonDecode(row.draftJson) as Map);
    final now = clock.now().toUtc();
    final routineId = decision == TreatmentProposalDecision.createRoutine
        ? uuid.v4()
        : targetRoutineId ?? (throw StateError('Target routine is required.'));
    final existingPlans =
        await (database.select(database.routinePlanRecords)
              ..where(
                (value) =>
                    value.userId.equals(userId) &
                    value.routineId.equals(routineId) &
                    value.deletedAt.isNull(),
              )
              ..orderBy([(value) => OrderingTerm.desc(value.revision)]))
            .get();
    if (decision != TreatmentProposalDecision.createRoutine &&
        existingPlans.isEmpty) {
      throw StateError('Target routine does not exist.');
    }
    final planRevision = existingPlans.isEmpty
        ? 1
        : existingPlans.first.revision + 1;
    final planId = decision == TreatmentProposalDecision.linkExisting
        ? existingPlans.first.id
        : uuid.v4();
    final linkId = uuid.v4();
    await database.transaction(() async {
      if (decision == TreatmentProposalDecision.createRoutine) {
        await database
            .into(database.smartRoutineRecords)
            .insert(
              SmartRoutineRecordsCompanion.insert(
                id: routineId,
                userId: userId,
                category: draft['category'] as String,
                displayName: draft['name'] as String,
                status: 'active',
                source: 'prescription',
                prescriptionId: Value(row.prescriptionId),
                prescriptionItemId: Value(row.prescriptionItemId),
                createdAt: now,
                updatedAt: now,
                syncStatus: SyncStatus.pendingCreate.name,
              ),
            );
      } else if (decision == TreatmentProposalDecision.createRevision) {
        final current = existingPlans.first;
        await (database.update(database.routinePlanRecords)..where(
              (value) =>
                  value.userId.equals(userId) & value.id.equals(current.id),
            ))
            .write(
              RoutinePlanRecordsCompanion(
                replacedAt: Value(now),
                updatedAt: Value(now),
                syncStatus: Value(SyncStatus.pendingUpdate.name),
              ),
            );
      }
      if (decision != TreatmentProposalDecision.linkExisting) {
        final effectiveFrom = draft['effectiveFrom'] as String;
        await database
            .into(database.routinePlanRecords)
            .insert(
              RoutinePlanRecordsCompanion.insert(
                id: planId,
                userId: userId,
                routineId: routineId,
                revision: planRevision,
                category: Value(draft['category'] as String),
                mode: draft['mode'] as String,
                durationType: draft['durationType'] as String,
                effectiveFrom: effectiveFrom,
                effectiveUntil: Value(draft['effectiveUntil'] as String?),
                doseValue: Value(draft['doseValue']?.toString()),
                doseUnit: Value(draft['doseUnit'] as String?),
                doseOriginalText: Value(draft['doseText'] as String?),
                route: Value(draft['route'] as String?),
                clinicalInstructions: Value(draft['instructions'] as String?),
                activatedAt: Value(now),
                previousPlanId: Value(existingPlans.firstOrNull?.id),
                provenanceOrigin: const Value('prescriptionImport'),
                validationStatus: const Value('confirmed'),
                provenancePrescriptionId: Value(row.prescriptionId),
                provenancePrescriptionItemId: Value(row.prescriptionItemId),
                provenanceDocumentId: Value(draft['documentId'] as String?),
                createdAt: now,
                updatedAt: now,
                syncStatus: SyncStatus.pendingCreate.name,
              ),
            );
        final scheduleRules = (draft['scheduleRules'] as List).cast<Map>();
        for (var index = 0; index < scheduleRules.length; index++) {
          await database
              .into(database.routineScheduleRecords)
              .insert(
                RoutineScheduleRecordsCompanion.insert(
                  id: uuid.v4(),
                  userId: userId,
                  routineId: routineId,
                  planId: planId,
                  ruleJson: jsonEncode(scheduleRules[index]),
                  timeZone: timeZone,
                  reminderPreference:
                      draft['reminderPreference'] as String? ?? 'disabled',
                  earlyToleranceSeconds: 0,
                  onTimeToleranceSeconds: 1800,
                  lateToleranceSeconds: 43200,
                  isEnabled: draft['activatable'] as bool,
                  displayOrder: index,
                  createdAt: now,
                  updatedAt: now,
                  syncStatus: SyncStatus.pendingCreate.name,
                ),
              );
        }
      }
      await database
          .into(database.prescriptionRoutineLinkRecords)
          .insert(
            PrescriptionRoutineLinkRecordsCompanion.insert(
              id: linkId,
              userId: userId,
              prescriptionId: row.prescriptionId,
              prescriptionVersionId: row.prescriptionVersionId,
              prescriptionItemId: row.prescriptionItemId,
              routineId: routineId,
              planId: planId,
              createdAt: now,
              updatedAt: now,
              syncStatus: SyncStatus.pendingCreate.name,
            ),
          );
      await (database.update(database.treatmentProposalRecords)..where(
            (value) =>
                value.userId.equals(userId) & value.id.equals(proposalId),
          ))
          .write(
            TreatmentProposalRecordsCompanion(
              decision: Value(decision.name),
              targetRoutineId: Value(routineId),
              resultingPlanId: Value(planId),
              confirmedAt: Value(now),
              updatedAt: Value(now),
              syncStatus: Value(SyncStatus.pendingUpdate.name),
            ),
          );
    });
    return PrescriptionRoutineLink(
      id: linkId,
      userId: userId,
      prescriptionId: row.prescriptionId,
      prescriptionVersionId: row.prescriptionVersionId,
      prescriptionItemId: row.prescriptionItemId,
      routineId: routineId,
      planId: planId,
      active: true,
      createdAt: now,
    );
  }

  Map<String, Object?> _treatmentDraft(
    MedicalPrescriptionItem item,
    MedicalPrescription prescription,
  ) {
    final rules = <Map<String, Object?>>[];
    if (item.asNeeded) {
      rules.add({'schemaVersion': 1, 'type': 'asNeeded'});
    } else if (item.scheduleTimes.isNotEmpty) {
      rules.add({
        'schemaVersion': 1,
        'type': item.daysOfWeek.isEmpty
            ? 'dailyAtTimes'
            : 'specificWeekdaysAtTimes',
        if (item.daysOfWeek.isNotEmpty) 'weekdays': item.daysOfWeek,
        'times': item.scheduleTimes,
      });
    } else {
      rules.add({
        'schemaVersion': 1,
        'type': 'freeForm',
        'instructions':
            item.instructions ?? item.frequencyType?.name ?? 'Não estruturado',
      });
    }
    final start = item.startDate ?? prescription.prescribedAt;
    return {
      'name': item.name,
      'category': item.itemType.name,
      'mode': item.asNeeded ? 'asNeeded' : 'scheduled',
      'durationType': item.endDate == null ? 'unknown' : 'bounded',
      'effectiveFrom': _localDate(start),
      'effectiveUntil': item.endDate == null ? null : _localDate(item.endDate!),
      'doseValue': item.dosageValue,
      'doseUnit': item.dosageUnit,
      'doseText': item.dosageValue == null
          ? null
          : '${item.dosageValue} ${item.dosageUnit ?? ''}'.trim(),
      'route': item.route,
      'instructions': item.instructions,
      'documentId': prescription.sourceDocumentId,
      'scheduleRules': rules,
      'activatable': item.asNeeded || item.scheduleTimes.isNotEmpty,
      'fieldConfidences': item.fieldConfidences,
      'provenance': item.provenance,
      'reminderPreference': item.provenance['reminderPreference'] ?? 'disabled',
    };
  }

  Future<PrescriptionVersion> _version(String id) async {
    final row =
        await (database.select(database.prescriptionVersionRecords)..where(
              (value) => value.userId.equals(userId) & value.id.equals(id),
            ))
            .getSingleOrNull();
    if (row == null || row.deletedAt != null) {
      throw StateError('Prescription version not found.');
    }
    return _versionFromRow(row);
  }

  PrescriptionVersion _versionFromRow(PrescriptionVersionRecord row) {
    final snapshot = Map<String, dynamic>.from(
      jsonDecode(row.snapshotJson) as Map,
    );
    return PrescriptionVersion(
      id: row.id,
      prescriptionId: row.prescriptionId,
      userId: row.userId,
      revision: row.revision,
      status: PrescriptionVersionStatus.values.byName(row.status),
      snapshot: MedicalPrescriptionDto.fromSupabaseRows(
        prescription: Map<String, dynamic>.from(
          snapshot['prescription'] as Map,
        ),
        items: (snapshot['items'] as List)
            .map((value) => Map<String, dynamic>.from(value as Map))
            .toList(growable: false),
      ).prescription,
      sourceProcessingId: row.sourceProcessingId,
      submittedAt: row.submittedAt,
      confirmedAt: row.confirmedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      syncStatus: SyncStatus.fromName(row.syncStatus),
    );
  }

  TreatmentProposal _proposalFromRow(TreatmentProposalRecord row) =>
      TreatmentProposal(
        id: row.id,
        userId: row.userId,
        prescriptionId: row.prescriptionId,
        prescriptionVersionId: row.prescriptionVersionId,
        prescriptionItemId: row.prescriptionItemId,
        decision: TreatmentProposalDecision.values.byName(row.decision),
        draft: Map<String, Object?>.from(jsonDecode(row.draftJson) as Map),
        targetRoutineId: row.targetRoutineId,
        resultingPlanId: row.resultingPlanId,
        confirmedAt: row.confirmedAt,
        createdAt: row.createdAt,
      );

  PrescriptionVersionRecordsCompanion _versionCompanion(
    PrescriptionVersion value,
  ) {
    final dto = MedicalPrescriptionDto(
      prescription: value.snapshot,
      metadata: SyncMetadata(
        id: value.snapshot.id,
        userId: userId,
        createdAt: value.snapshot.createdAt,
        updatedAt: value.snapshot.updatedAt,
        deletedAt: value.snapshot.deletedAt,
        syncStatus: value.snapshot.syncStatus,
      ),
    );
    return PrescriptionVersionRecordsCompanion.insert(
      id: value.id,
      userId: userId,
      prescriptionId: value.prescriptionId,
      revision: value.revision,
      status: value.status.name,
      snapshotJson: jsonEncode({
        'prescription': dto.toSupabasePrescriptionRow(),
        'items': dto.toSupabaseItemRows(),
      }),
      sourceProcessingId: Value(value.sourceProcessingId),
      submittedAt: Value(value.submittedAt),
      confirmedAt: Value(value.confirmedAt),
      createdAt: value.createdAt,
      updatedAt: value.updatedAt,
      syncStatus: value.syncStatus.name,
    );
  }

  Future<void> _updateVersion(
    PrescriptionVersion current, {
    required PrescriptionVersionStatus status,
    required DateTime updatedAt,
    DateTime? submittedAt,
    DateTime? confirmedAt,
  }) =>
      (database.update(database.prescriptionVersionRecords)..where(
            (row) => row.userId.equals(userId) & row.id.equals(current.id),
          ))
          .write(
            PrescriptionVersionRecordsCompanion(
              status: Value(status.name),
              submittedAt: Value(submittedAt ?? current.submittedAt),
              confirmedAt: Value(confirmedAt ?? current.confirmedAt),
              updatedAt: Value(updatedAt),
              syncStatus: Value(SyncStatus.pendingUpdate.name),
            ),
          );

  void _validateForConfirmation(MedicalPrescription value) {
    if (value.activeItems.isEmpty ||
        value.activeItems.any((item) => item.name.trim().isEmpty)) {
      throw const FormatException('Prescription requires reviewed items.');
    }
  }

  void _requireUser(String value) {
    if (value != userId) throw StateError('Prescription user mismatch.');
  }

  String _localDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
