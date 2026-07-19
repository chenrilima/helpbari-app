import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/sync/sync.dart';
import 'package:helpbari/features/medical_prescriptions/data/dtos/medical_prescription_dto.dart';
import 'package:helpbari/features/medical_prescriptions/domain/entities/entities.dart';

void main() {
  test(
    'Supabase mapping preserves dates, enums, JSON, links and tombstones',
    () {
      final now = DateTime.utc(2026, 7, 19, 12);
      final entity = MedicalPrescription(
        id: 'p-1',
        userId: 'user-1',
        prescribedAt: now,
        status: MedicalPrescriptionStatus.confirmed,
        items: [
          MedicalPrescriptionItem(
            id: 'i-1',
            prescriptionId: 'p-1',
            userId: 'user-1',
            itemType: PrescriptionItemType.vitamin,
            name: 'Vitamina D',
            frequencyType: PrescriptionFrequencyType.specificTimes,
            scheduleTimes: const ['08:00'],
            daysOfWeek: const [1, 3, 5],
            fieldConfidences: const {'name': .9},
            provenance: const {'name': 'ocr'},
            linkedVitaminId: 'v-1',
            reviewStatus: PrescriptionReviewStatus.confirmed,
            createdAt: now,
            updatedAt: now,
            deletedAt: now,
            syncStatus: SyncStatus.pendingDelete,
          ),
        ],
        createdAt: now,
        updatedAt: now,
        deletedAt: now,
        syncStatus: SyncStatus.pendingDelete,
      );
      final dto = MedicalPrescriptionDto(
        prescription: entity,
        metadata: SyncMetadata(
          id: entity.id,
          userId: entity.userId,
          createdAt: now,
          updatedAt: now,
          deletedAt: now,
          syncStatus: SyncStatus.pendingDelete,
        ),
      );
      final decoded = MedicalPrescriptionDto.fromSupabaseRows(
        prescription: dto.toSupabasePrescriptionRow(),
        items: dto.toSupabaseItemRows(),
      );
      final item = decoded.prescription.items.single;
      expect(decoded.prescription.userId, 'user-1');
      expect(decoded.metadata.isDeleted, isTrue);
      expect(item.itemType, PrescriptionItemType.vitamin);
      expect(item.scheduleTimes, ['08:00']);
      expect(item.daysOfWeek, [1, 3, 5]);
      expect(item.fieldConfidences['name'], .9);
      expect(item.linkedVitaminId, 'v-1');
    },
  );
}
