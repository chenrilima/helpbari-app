import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/sync/sync.dart';
import 'package:helpbari/features/medical_prescriptions/domain/entities/entities.dart';
import 'package:helpbari/features/medical_prescriptions/domain/repositories/repositories.dart';
import 'package:helpbari/features/medical_prescriptions/domain/usecases/use_cases.dart';

void main() {
  test(
    'manual prescription can be confirmed, archived and soft deleted',
    () async {
      final repository = _Repository();
      final useCases = MedicalPrescriptionUseCases(repository);
      final value = _prescription();
      await useCases.create(value);
      await useCases.confirm(value, DateTime.utc(2026, 7, 19, 12));
      expect(repository.value!.status, MedicalPrescriptionStatus.confirmed);
      expect(
        repository.value!.items.single.reviewStatus,
        PrescriptionReviewStatus.confirmed,
      );
      await useCases.archive(repository.value!, DateTime.utc(2026, 7, 20));
      expect(repository.value!.status, MedicalPrescriptionStatus.archived);
      await useCases.delete(value.id);
      expect(repository.value!.deletedAt, isNotNull);
    },
  );

  test('frequency, schedules, duration and as-needed remain structured', () {
    final item = _prescription().items.single.copyWith(
      frequencyType: PrescriptionFrequencyType.everyHours,
      frequencyValue: 8,
      scheduleTimes: ['08:00', '16:00'],
      durationValue: 7,
      durationUnit: 'days',
      asNeeded: true,
    );
    expect(item.frequencyValue, 8);
    expect(item.scheduleTimes, hasLength(2));
    expect(item.durationValue, 7);
    expect(item.asNeeded, isTrue);
  });

  test('potential duplicate uses document id or confirmed signature', () async {
    final repository = _Repository()
      ..value = _prescription().copyWith(
        status: MedicalPrescriptionStatus.confirmed,
      );
    final candidate = MedicalPrescription(
      id: 'p-2',
      userId: 'user-1',
      prescribedAt: DateTime.utc(2026, 7, 19),
      sourceDocumentId: 'doc-1',
      status: MedicalPrescriptionStatus.draft,
      createdAt: DateTime.utc(2026, 7, 19),
      updatedAt: DateTime.utc(2026, 7, 19),
      syncStatus: SyncStatus.pendingCreate,
    );
    final duplicate = await MedicalPrescriptionUseCases(
      repository,
    ).findPotentialDuplicate(candidate);
    expect(duplicate, isNotNull);
  });
}

MedicalPrescription _prescription() {
  final now = DateTime.utc(2026, 7, 19);
  return MedicalPrescription(
    id: 'p-1',
    userId: 'user-1',
    professionalName: 'Dra. Ana',
    prescribedAt: now,
    sourceDocumentId: 'doc-1',
    status: MedicalPrescriptionStatus.draft,
    items: [
      MedicalPrescriptionItem(
        id: 'i-1',
        prescriptionId: 'p-1',
        userId: 'user-1',
        itemType: PrescriptionItemType.medication,
        name: 'Medicamento A',
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

class _Repository implements MedicalPrescriptionRepository {
  MedicalPrescription? value;
  @override
  Future<void> delete(String id) async {
    value = value?.copyWith(deletedAt: DateTime.utc(2026, 7, 21));
  }

  @override
  Future<List<MedicalPrescription>> getAll() async => [?value];
  @override
  Future<MedicalPrescription?> getById(String id) async => value;
  @override
  Future<void> save(MedicalPrescription prescription) async =>
      value = prescription;
  @override
  Stream<List<MedicalPrescription>> watchAll() => Stream.value([?value]);
}
