import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/drift/app_database.dart';
import 'package:helpbari/core/services/clock_service.dart';
import 'package:helpbari/core/sync/sync.dart';
import 'package:helpbari/core/time/iana_timezone_bootstrap.dart';
import 'package:helpbari/features/medical_prescriptions/data/datasources/drift_medical_prescription_local_datasource.dart';
import 'package:helpbari/features/medical_prescriptions/data/repositories/drift_prescription_platform_repository.dart';
import 'package:helpbari/features/medical_prescriptions/domain/entities/entities.dart';

void main() {
  setUpAll(IanaTimezoneBootstrap.initialize);
  late AppDatabase database;
  late DriftPrescriptionPlatformRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = DriftPrescriptionPlatformRepository(
      database: database,
      prescriptions: DriftMedicalPrescriptionLocalDatasource(
        dao: database.medicalPrescriptionDao,
        clock: const _Clock(),
        userId: 'user-a',
      ),
      clock: const _Clock(),
      userId: 'user-a',
      timeZone: 'America/Sao_Paulo',
    );
  });

  tearDown(() => database.close());

  test('confirmation requires review and is idempotently rejected', () async {
    final draft = await repository.createDraftVersion(snapshot: _value());

    await expectLater(
      repository.confirmVersion(
        versionId: draft.id,
        actor: 'patient',
        fieldDecisions: const {},
      ),
      throwsStateError,
    );
    await repository.submitForReview(draft.id);
    final confirmed = await repository.confirmVersion(
      versionId: draft.id,
      actor: 'patient',
      fieldDecisions: const {'all': 'humanConfirmed'},
    );

    expect(confirmed.status, PrescriptionVersionStatus.confirmed);
    await expectLater(
      repository.confirmVersion(
        versionId: draft.id,
        actor: 'patient',
        fieldDecisions: const {},
      ),
      throwsStateError,
    );
    expect(
      await database.select(database.prescriptionReviewRecords).get(),
      hasLength(2),
    );
  });

  test(
    'rejection is audited and immutable lifecycle cannot be reopened',
    () async {
      final draft = await repository.createDraftVersion(snapshot: _value());
      await repository.submitForReview(draft.id, actor: 'patient');

      final rejected = await repository.rejectVersion(
        versionId: draft.id,
        actor: 'patient',
        fieldDecisions: const {'dose': 'rejected'},
        note: 'Dose ilegível',
      );

      expect(rejected.status, PrescriptionVersionStatus.archived);
      await expectLater(repository.submitForReview(draft.id), throwsStateError);
      await expectLater(
        repository.confirmVersion(
          versionId: draft.id,
          actor: 'patient',
          fieldDecisions: const {},
        ),
        throwsStateError,
      );
      final reviews = await database
          .select(database.prescriptionReviewRecords)
          .get();
      expect(reviews.map((value) => value.decision), ['submitted', 'rejected']);
    },
  );

  test(
    'confirmed snapshot is database-immutable and may only archive',
    () async {
      final draft = await repository.createDraftVersion(snapshot: _value());
      await repository.submitForReview(draft.id);
      await repository.confirmVersion(
        versionId: draft.id,
        actor: 'patient',
        fieldDecisions: const {'all': 'humanConfirmed'},
      );

      await expectLater(
        (database.update(
          database.prescriptionVersionRecords,
        )..where((row) => row.id.equals(draft.id))).write(
          const PrescriptionVersionRecordsCompanion(snapshotJson: Value('{}')),
        ),
        throwsA(anything),
      );
      final archived = await repository.archiveVersion(draft.id);
      expect(archived.status, PrescriptionVersionStatus.archived);
    },
  );

  test('new edits create immutable monotonic versions', () async {
    final first = await repository.createDraftVersion(snapshot: _value());
    final second = await repository.createDraftVersion(
      snapshot: _value(name: 'Dose revisada'),
    );

    expect(second.revision, 2);
    expect(first.snapshot.items.single.name, 'Item A');
    expect((await repository.history('p-1')).map((value) => value.revision), [
      2,
      1,
    ]);
  });

  test('same document processing is idempotent', () async {
    final first = await repository.createDraftVersion(
      snapshot: _value(),
      sourceProcessingId: 'processing-a',
    );
    final retry = await repository.createDraftVersion(
      snapshot: _value(),
      sourceProcessingId: 'processing-a',
    );

    expect(retry.id, first.id);
    expect(await repository.history('p-1'), hasLength(1));
  });

  test(
    'proposal creates routine, plan, every schedule and link atomically',
    () async {
      final version = await repository.createDraftVersion(
        snapshot: _value(times: const ['08:00', '20:00']),
      );
      await repository.submitForReview(version.id);
      await repository.confirmVersion(
        versionId: version.id,
        actor: 'patient',
        fieldDecisions: const {'all': 'humanConfirmed'},
      );
      final proposal = (await repository.createProposals(version.id)).single;

      final link = await repository.confirmProposal(
        proposalId: proposal.id,
        decision: TreatmentProposalDecision.createRoutine,
      );

      expect(
        await database.select(database.smartRoutineRecords).get(),
        hasLength(1),
      );
      expect(
        await database.select(database.routinePlanRecords).get(),
        hasLength(1),
      );
      final schedules = await database
          .select(database.routineScheduleRecords)
          .get();
      expect(schedules, hasLength(1));
      expect(schedules.single.ruleJson, contains('08:00'));
      expect(schedules.single.ruleJson, contains('20:00'));
      expect(link.planId, schedules.single.planId);
      await expectLater(
        repository.confirmProposal(
          proposalId: proposal.id,
          decision: TreatmentProposalDecision.createRoutine,
        ),
        throwsStateError,
      );
    },
  );

  test(
    'unstructured proposal remains reviewable and cannot activate',
    () async {
      final version = await repository.createDraftVersion(
        snapshot: _value(times: const []),
      );
      await repository.submitForReview(version.id);
      await repository.confirmVersion(
        versionId: version.id,
        actor: 'patient',
        fieldDecisions: const {'all': 'humanConfirmed'},
      );
      final proposal = (await repository.createProposals(version.id)).single;

      await expectLater(
        repository.confirmProposal(
          proposalId: proposal.id,
          decision: TreatmentProposalDecision.createRoutine,
        ),
        throwsStateError,
      );
      expect(
        await database.select(database.smartRoutineRecords).get(),
        isEmpty,
      );
      expect(
        await database.select(database.prescriptionRoutineLinkRecords).get(),
        isEmpty,
      );
    },
  );

  test('every-hours prescription preserves absolute interval rule', () async {
    final version = await repository.createDraftVersion(
      snapshot: _value(
        frequencyType: PrescriptionFrequencyType.everyHours,
        frequencyValue: 8,
      ),
    );
    await repository.submitForReview(version.id);
    await repository.confirmVersion(
      versionId: version.id,
      actor: 'patient',
      fieldDecisions: const {'all': 'humanConfirmed'},
    );

    final proposal = (await repository.createProposals(version.id)).single;
    expect(proposal.draft['scheduleRules'].toString(), contains('everyNHours'));
    expect(proposal.draft['scheduleRules'].toString(), contains('anchorAtUtc'));
  });
}

MedicalPrescription _value({
  String name = 'Item A',
  List<String> times = const ['08:00'],
  PrescriptionFrequencyType? frequencyType,
  int? frequencyValue,
}) {
  final now = DateTime.utc(2026, 7, 21, 12);
  return MedicalPrescription(
    id: 'p-1',
    userId: 'user-a',
    prescribedAt: now,
    status: MedicalPrescriptionStatus.draft,
    items: [
      MedicalPrescriptionItem(
        id: 'i-1',
        prescriptionId: 'p-1',
        userId: 'user-a',
        itemType: PrescriptionItemType.medication,
        name: name,
        dosageValue: 10,
        dosageUnit: 'mg',
        scheduleTimes: times,
        frequencyType: frequencyType,
        frequencyValue: frequencyValue,
        reviewStatus: PrescriptionReviewStatus.reviewed,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.pendingCreate,
      ),
    ],
    createdAt: now,
    updatedAt: now,
    syncStatus: SyncStatus.pendingCreate,
  );
}

class _Clock implements ClockService {
  const _Clock();
  @override
  DateTime now() => DateTime.utc(2026, 7, 21, 12);
}
