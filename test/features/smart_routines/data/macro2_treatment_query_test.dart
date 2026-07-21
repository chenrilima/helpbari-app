import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/database/drift/app_database.dart';
import 'package:helpbari/core/services/clock_service.dart';
import 'package:helpbari/features/smart_routines/application/notification_platform.dart';
import 'package:helpbari/features/smart_routines/data/repositories/drift_notification_platform_repository.dart';
import 'package:helpbari/features/smart_routines/data/repositories/drift_treatment_query_service.dart';
import 'package:helpbari/features/smart_routines/domain/enums/routine_enums.dart';

void main() {
  late AppDatabase database;
  late DriftTreatmentAdherenceQueryService queries;
  final now = DateTime.now().toUtc();

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    queries = DriftTreatmentAdherenceQueryService(
      database: database,
      userId: 'user-a',
      clock: _Clock(now),
    );
    await _insertOccurrence(database, now);
  });

  tearDown(() => database.close());

  test(
    'known pending occurrence has complete coverage without zero adherence',
    () async {
      final summary = await queries.summary(now, now);

      expect(summary.coverageState, AdherenceCoverageState.complete);
      expect(summary.coverage, 1);
      expect(summary.eligible, 0);
      expect(summary.adherence, isNull);
    },
  );

  test(
    'conflicting terminal events are explicit unavailable coverage',
    () async {
      await _event(
        database,
        '51111111-1111-4111-8111-111111111111',
        'taken',
        now,
      );
      await _event(
        database,
        '61111111-1111-4111-8111-111111111111',
        'skipped',
        now,
      );

      final summary = await queries.summary(now, now);
      final today = await queries.today(now);

      expect(summary.coverageState, AdherenceCoverageState.partial);
      expect(summary.eligible, 0);
      expect(
        today.occurrences.single.state,
        OccurrenceAdherenceState.inconsistent,
      );
    },
  );

  test(
    'notification command is idempotent and promotes occurrence for sync atomically',
    () async {
      final repository = DriftNotificationPlatformRepository(
        database: database,
        clock: _Clock(now),
      );

      await repository.markOccurrence(
        userId: 'user-a',
        occurrenceId: _occurrenceId,
        actionId: 'delivery-a',
        action: RoutineNotificationActionType.taken,
        occurredAtUtc: now,
      );
      await repository.markOccurrence(
        userId: 'user-a',
        occurrenceId: _occurrenceId,
        actionId: 'delivery-a',
        action: RoutineNotificationActionType.taken,
        occurredAtUtc: now,
      );

      expect(
        await database.select(database.routineAdherenceEventRecords).get(),
        hasLength(1),
      );
      expect(
        (await database.select(database.routineOccurrenceRecords).get())
            .single
            .syncStatus,
        'pendingCreate',
      );
    },
  );
}

Future<void> _insertOccurrence(AppDatabase database, DateTime now) => database
    .into(database.routineOccurrenceRecords)
    .insert(
      RoutineOccurrenceRecordsCompanion.insert(
        id: _occurrenceId,
        userId: 'user-a',
        routineId: _routineId,
        planId: _planId,
        scheduleId: const Value(_scheduleId),
        origin: 'generated',
        status: 'expected',
        originalClinicalDate:
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        originalLocalHour: now.hour,
        originalLocalMinute: now.minute,
        originalTimeZone: 'UTC',
        expectationKind: 'recurringExpectation',
        sequence: 0,
        originalScheduledFor: now,
        originalWindowStartsAt: now,
        originalOnTimeEndsAt: now.add(const Duration(minutes: 30)),
        originalWindowEndsAt: now.add(const Duration(hours: 12)),
        scheduledFor: now,
        windowStartsAt: now,
        onTimeEndsAt: now.add(const Duration(minutes: 30)),
        windowEndsAt: now.add(const Duration(hours: 12)),
        createdAt: now,
        updatedAt: now,
        syncStatus: 'synced',
      ),
    );

Future<void> _event(
  AppDatabase database,
  String id,
  String type,
  DateTime at,
) => database
    .into(database.routineAdherenceEventRecords)
    .insert(
      RoutineAdherenceEventRecordsCompanion.insert(
        id: id,
        userId: 'user-a',
        occurrenceId: _occurrenceId,
        routineId: _routineId,
        planId: _planId,
        scheduleId: const Value(_scheduleId),
        type: type,
        actor: 'user',
        occurredAtUtc: at,
        recordedAtUtc: at,
        createdAt: at,
        updatedAt: at,
        syncStatus: 'pendingCreate',
      ),
    );

const _occurrenceId = '11111111-1111-4111-8111-111111111111';
const _routineId = '21111111-1111-4111-8111-111111111111';
const _planId = '31111111-1111-4111-8111-111111111111';
const _scheduleId = '41111111-1111-4111-8111-111111111111';

class _Clock implements ClockService {
  const _Clock(this.value);
  final DateTime value;
  @override
  DateTime now() => value;
}
