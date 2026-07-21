import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/drift/app_database.dart';
import 'package:helpbari/core/supabase/database/supabase_database.dart';
import 'package:helpbari/core/supabase/interceptors/supabase_request_interceptor.dart';
import 'package:helpbari/features/medical_prescriptions/data/repositories/prescription_platform_sync_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('pending operations decode Drift Unix timestamps', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final timestamp = DateTime.utc(2026, 7, 21, 12, 30);
    await database
        .into(database.prescriptionVersionRecords)
        .insert(
          PrescriptionVersionRecordsCompanion.insert(
            id: 'version-1',
            userId: 'user-1',
            prescriptionId: 'prescription-1',
            revision: 1,
            status: 'draft',
            snapshotJson: '{}',
            submittedAt: const Value.absent(),
            confirmedAt: const Value.absent(),
            createdAt: timestamp,
            updatedAt: timestamp,
            syncStatus: 'pendingCreate',
          ),
        );
    final repository = PrescriptionPlatformSyncRepository(
      database: database,
      remote: SupabaseDatabase(
        client: SupabaseClient('https://example.supabase.co', 'test-key'),
        interceptorRunner: const SupabaseInterceptorRunner([]),
      ),
      userId: 'user-1',
    );

    final operation = (await repository.pendingOperations()).single;

    expect(operation.updatedAt, timestamp);
    expect(
      (operation.payload['row'] as Map<String, Object?>)['updated_at'],
      timestamp.toIso8601String(),
    );
  });

  test('pending operations keep parents before dependent rows', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final parentTimestamp = DateTime.utc(2026, 7, 21, 13);
    final childTimestamp = parentTimestamp.subtract(const Duration(hours: 1));
    await database
        .into(database.prescriptionVersionRecords)
        .insert(
          PrescriptionVersionRecordsCompanion.insert(
            id: 'version-1',
            userId: 'user-1',
            prescriptionId: 'prescription-1',
            revision: 1,
            status: 'requiresReview',
            snapshotJson: '{}',
            createdAt: parentTimestamp,
            updatedAt: parentTimestamp,
            syncStatus: 'pendingCreate',
          ),
        );
    await database
        .into(database.prescriptionReviewRecords)
        .insert(
          PrescriptionReviewRecordsCompanion.insert(
            id: 'review-1',
            userId: 'user-1',
            prescriptionId: 'prescription-1',
            versionId: 'version-1',
            decision: 'submitted',
            actor: 'patient',
            fieldDecisionsJson: '{}',
            createdAt: childTimestamp,
            updatedAt: childTimestamp,
            syncStatus: 'pendingCreate',
          ),
        );
    final repository = PrescriptionPlatformSyncRepository(
      database: database,
      remote: SupabaseDatabase(
        client: SupabaseClient('https://example.supabase.co', 'test-key'),
        interceptorRunner: const SupabaseInterceptorRunner([]),
      ),
      userId: 'user-1',
    );

    final operations = await repository.pendingOperations();

    expect(operations.map((operation) => operation.payload['table']), [
      'prescription_versions',
      'prescription_reviews',
    ]);
  });
}
