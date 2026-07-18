import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/drift/app_database.dart'
    hide MedicalConsultation;
import 'package:helpbari/core/services/clock_service.dart';
import 'package:helpbari/core/sync/sync.dart';
import 'package:helpbari/features/medical_consultations/data/datasources/drift_medical_consultation_local_datasource.dart';
import 'package:helpbari/features/medical_consultations/data/dtos/medical_consultation_dto.dart';
import 'package:helpbari/features/medical_consultations/domain/entities/entities.dart';

void main() {
  late AppDatabase database;
  final now = DateTime.utc(2026, 7, 18, 12);

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test('saves links, tombstones and excludes anonymous from sync', () async {
    final datasource = DriftMedicalConsultationLocalDatasource(
      dao: database.medicalConsultationDao,
      clock: _FixedClock(now),
      userId: 'user-1',
    );

    await datasource.save(_consultation(now));

    final saved = (await datasource.getHistory()).single;
    expect(saved.relatedExamIds, ['exam-1']);
    expect(saved.relatedBodyCompositionIds, ['bio-1']);
    expect(
      (await datasource.pendingSync()).single.syncMetadata.syncStatus,
      SyncStatus.pendingCreate,
    );

    await datasource.delete('consultation-1');

    expect(await datasource.getHistory(), isEmpty);
    expect(
      (await datasource.pendingSync()).single.syncMetadata.syncStatus,
      SyncStatus.pendingDelete,
    );

    final anonymous = DriftMedicalConsultationLocalDatasource(
      dao: database.medicalConsultationDao,
      clock: _FixedClock(now),
      userId: anonymousMedicalConsultationUserId,
    );
    await anonymous.save(
      _consultation(now, userId: anonymousMedicalConsultationUserId),
    );
    expect(await anonymous.pendingSync(), isEmpty);
  });

  test('latest updatedAt wins during remote application', () async {
    final datasource = DriftMedicalConsultationLocalDatasource(
      dao: database.medicalConsultationDao,
      clock: _FixedClock(now),
      userId: 'user-1',
    );

    await datasource.save(_consultation(now));
    await datasource.applyRemoteAndMarkSynced(
      _dto(now.add(const Duration(minutes: 1)), title: 'Retorno nutricional'),
    );

    expect((await datasource.getHistory()).single.title, 'Retorno nutricional');
    expect(
      (await datasource.pendingById('consultation-1'))?.syncMetadata.syncStatus,
      SyncStatus.synced,
    );

    await datasource.applyRemote(
      _dto(now.subtract(const Duration(minutes: 1)), title: 'Consulta antiga'),
    );

    expect((await datasource.getHistory()).single.title, 'Retorno nutricional');
  });
}

MedicalConsultation _consultation(
  DateTime now, {
  String userId = 'user-1',
  String title = 'Consulta de rotina',
}) => MedicalConsultation(
  id: 'consultation-1',
  userId: userId,
  consultationAt: DateTime.utc(2026, 7, 18, 8),
  title: title,
  professionalName: 'Dra. Ana',
  reason: 'Acompanhamento pós-operatório',
  professionalGuidance: 'Manter hidratação.',
  source: MedicalConsultationSource.manual,
  relatedExamIds: const ['exam-1'],
  relatedBodyCompositionIds: const ['bio-1'],
  createdAt: now,
  updatedAt: now,
  syncStatus: SyncStatus.pendingCreate,
);

MedicalConsultationDto _dto(DateTime updatedAt, {required String title}) =>
    MedicalConsultationDto.fromEntity(
      _consultation(updatedAt, title: title),
      now: updatedAt,
      previousMetadata: SyncMetadata(
        id: 'consultation-1',
        userId: 'user-1',
        createdAt: nowBase,
        updatedAt: updatedAt,
        syncStatus: SyncStatus.pendingUpdate,
      ),
    );

final nowBase = DateTime.utc(2026, 7, 1);

class _FixedClock implements ClockService {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}
