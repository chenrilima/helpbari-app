import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/drift/app_database.dart';
import 'package:helpbari/core/services/clock_service.dart';
import 'package:helpbari/core/sync/sync.dart';
import 'package:helpbari/features/medical_prescriptions/data/datasources/drift_medical_prescription_local_datasource.dart';
import 'package:helpbari/features/medical_prescriptions/domain/entities/entities.dart';

void main() {
  late AppDatabase database;
  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test('CRUD, watch, user isolation, links and tombstones', () async {
    final userA = _local(database, 'user-a');
    final userB = _local(database, 'user-b');
    await userA.save(_value('user-a'));
    await userB.save(_value('user-b'));
    expect((await userA.getAll()).single.userId, 'user-a');
    expect(await userA.watchAll().first, hasLength(1));
    final linked = (await userA.getAll()).single;
    await userA.save(
      linked.copyWith(
        items: [linked.items.single.copyWith(linkedMedicationId: 'med-1')],
      ),
    );
    expect(
      (await userA.getAll()).single.items.single.linkedMedicationId,
      'med-1',
    );
    await userA.delete('p-1');
    expect(await userA.getAll(), isEmpty);
    final pending = await userA.pendingSync();
    expect(pending.single.metadata.isDeleted, isTrue);
    expect(pending.single.prescription.items.single.deletedAt, isNotNull);
    expect(await userB.getAll(), hasLength(1));
  });

  test('schema 17 creates prescription indexes', () async {
    expect(database.schemaVersion, 23);
    final rows = await database
        .customSelect("PRAGMA index_list('medical_prescription_records')")
        .get();
    expect(
      rows.map((row) => row.read<String>('name')),
      contains('medical_prescriptions_user_date_idx'),
    );
  });

  test(
    'review projection counts distinct prescriptions and isolates user',
    () async {
      final userA = _local(database, 'user-a');
      final userB = _local(database, 'user-b');
      final pending = _value('user-a').copyWith(
        status: MedicalPrescriptionStatus.requiresReview,
        items: [
          _value('user-a').items.single.copyWith(
            reviewStatus: PrescriptionReviewStatus.pending,
          ),
        ],
      );
      await userA.save(pending);
      await userB.save(
        _value(
          'user-b',
        ).copyWith(status: MedicalPrescriptionStatus.requiresReview),
      );

      expect(await userA.countRequiringReview(), 1);
      expect(await userB.countRequiringReview(), 1);
      expect(await userA.getLimited(limit: 1), hasLength(1));
    },
  );
}

DriftMedicalPrescriptionLocalDatasource _local(AppDatabase db, String user) =>
    DriftMedicalPrescriptionLocalDatasource(
      dao: db.medicalPrescriptionDao,
      clock: const _Clock(),
      userId: user,
    );

MedicalPrescription _value(String user) {
  final now = DateTime.utc(2026, 7, 19);
  return MedicalPrescription(
    id: 'p-1',
    userId: user,
    prescribedAt: now,
    status: MedicalPrescriptionStatus.confirmed,
    items: [
      MedicalPrescriptionItem(
        id: 'i-1',
        prescriptionId: 'p-1',
        userId: user,
        itemType: PrescriptionItemType.medication,
        name: 'Item A',
        reviewStatus: PrescriptionReviewStatus.confirmed,
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
  DateTime now() => DateTime.utc(2026, 7, 19, 12);
}
