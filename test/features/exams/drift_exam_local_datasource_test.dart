import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/drift/app_database.dart';
import 'package:helpbari/core/database/drift/consistency/exam_local_consistency_checker.dart';
import 'package:helpbari/core/database/drift/cutover/exam_cutover_service.dart';
import 'package:helpbari/core/database/drift/migrations/exam_legacy_service.dart';
import 'package:helpbari/core/database/local_database_record.dart';
import 'package:helpbari/core/services/clock_service.dart';
import 'package:helpbari/core/services/local_storage_service.dart';
import 'package:helpbari/core/sync/sync.dart';
import 'package:helpbari/features/exams/data/datasources/drift_exam_local_datasource.dart';
import 'package:helpbari/features/exams/data/dtos/exam_dto.dart';

void main() {
  late AppDatabase db;
  final now = DateTime.utc(2026, 7, 12);
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());
  test('CRUD conflict tombstone cursor users and anonymous', () async {
    final a = DriftExamLocalDatasource(
      dao: db.examDao,
      clock: _Clock(now),
      userId: 'a',
    );
    await a.save(_dto(now));
    expect(await a.getAll(), hasLength(1));
    await a.applyRemoteAndMarkSynced(
      _dto(now.add(const Duration(minutes: 1)), name: 'Novo'),
    );
    expect((await a.getAll()).single.name, 'Novo');
    await a.applyRemote(_dto(now, name: 'Antigo'));
    expect((await a.getAll()).single.name, 'Novo');
    await a.saveCursor('exams', now);
    expect((await a.getLastPullAt('exams'))?.toUtc(), now);
    final b = DriftExamLocalDatasource(
      dao: db.examDao,
      clock: _Clock(now),
      userId: 'b',
    );
    expect(await b.getAll(), isEmpty);
    expect(await b.getLastPullAt('exams'), isNull);
    final anonymous = DriftExamLocalDatasource(
      dao: db.examDao,
      clock: _Clock(now),
      userId: anonymousExamUserId,
    );
    await anonymous.save(_dto(now));
    expect(await anonymous.pendingSync(), isEmpty);
    await a.delete('exam');
    expect(await a.getAll(), isEmpty);
  });
  test('legacy migration cutover and SharedPreferences intact', () async {
    final s = _Storage();
    final r = LocalDatabaseRecord(
      metadata: SyncMetadata(
        id: 'legacy',
        userId: 'a',
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.pendingCreate,
      ),
      data: {
        'name': 'Hemograma',
        'examDate': now.toIso8601String(),
        'laboratory': null,
        'notes': null,
        'attachmentPath': null,
      },
    );
    s.legacy = jsonEncode([r.toJson()]);
    final original = s.legacy;
    await ExamLegacyService(database: db, storage: s).migrate();
    expect(
      (await ExamLocalConsistencyChecker(
        database: db,
        storage: s,
      ).check(userId: 'a')).consistent,
      isTrue,
    );
    final c = ExamCutoverService(database: db, storage: s);
    expect(await c.attempt('a'), isTrue);
    expect(await c.attempt(anonymousExamUserId), isFalse);
    expect(s.legacy, original);
  });
}

ExamDto _dto(DateTime updatedAt, {String name = 'Exame'}) => ExamDto(
  id: 'exam',
  name: name,
  examDate: DateTime.utc(2026, 7, 1),
  syncMetadata: SyncMetadata(
    id: 'exam',
    userId: 'a',
    createdAt: DateTime.utc(2026, 6, 1),
    updatedAt: updatedAt,
    syncStatus: SyncStatus.pendingCreate,
  ),
);

class _Clock implements ClockService {
  const _Clock(this.v);
  final DateTime v;
  @override
  DateTime now() => v;
}

class _Storage implements LocalStorageService {
  String? legacy;
  final m = <String, String>{};
  @override
  bool? getBool(String k) => null;
  @override
  String? getString(String k) => k == examLegacyStorageKey ? legacy : m[k];
  @override
  Future<void> setBool(String k, bool v) async {}
  @override
  Future<void> setString(String k, String v) async {
    m[k] = v;
  }
}
