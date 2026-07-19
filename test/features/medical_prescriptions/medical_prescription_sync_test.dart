import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/drift/app_database.dart';
import 'package:helpbari/core/services/clock_service.dart';
import 'package:helpbari/core/supabase/database/supabase_database.dart';
import 'package:helpbari/core/supabase/interceptors/supabase_request_interceptor.dart';
import 'package:helpbari/core/sync/sync.dart';
import 'package:helpbari/features/medical_prescriptions/data/datasources/drift_medical_prescription_local_datasource.dart';
import 'package:helpbari/features/medical_prescriptions/data/datasources/medical_prescription_supabase_datasource.dart';
import 'package:helpbari/features/medical_prescriptions/data/repositories/medical_prescription_sync_repository.dart';
import 'package:helpbari/features/medical_prescriptions/domain/entities/entities.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'sync emits one aggregate operation with parent before its items',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final local = DriftMedicalPrescriptionLocalDatasource(
        dao: database.medicalPrescriptionDao,
        clock: const _Clock(),
        userId: 'user-1',
      );
      final now = DateTime.utc(2026, 7, 19);
      await local.save(
        MedicalPrescription(
          id: '00000000-0000-0000-0000-000000000001',
          userId: 'user-1',
          prescribedAt: now,
          status: MedicalPrescriptionStatus.confirmed,
          items: [
            MedicalPrescriptionItem(
              id: '00000000-0000-0000-0000-000000000002',
              prescriptionId: '00000000-0000-0000-0000-000000000001',
              userId: 'user-1',
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
        ),
      );
      final repository = MedicalPrescriptionSyncRepository(
        local: () async => local,
        remote: MedicalPrescriptionSupabaseDatasource(
          SupabaseDatabase(
            client: SupabaseClient('https://example.supabase.co', 'test-key'),
            interceptorRunner: const SupabaseInterceptorRunner([]),
          ),
        ),
        userId: 'user-1',
      );
      final operations = await repository.pendingOperations();
      expect(operations, hasLength(1));
      expect(
        operations.single.repositoryKey,
        MedicalPrescriptionSyncRepository.key,
      );
      expect(operations.single.payload['prescription'], isA<Map>());
      expect(operations.single.payload['items'], isA<List>());
      expect(operations.single.userId, 'user-1');
    },
  );
}

class _Clock implements ClockService {
  const _Clock();
  @override
  DateTime now() => DateTime.utc(2026, 7, 19, 12);
}
