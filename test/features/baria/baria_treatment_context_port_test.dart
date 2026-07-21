import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/baria/domain/ports/baria_treatment_context_port.dart';
import 'package:helpbari/features/smart_routines/domain/enums/routine_enums.dart';
import 'package:helpbari/features/smart_routines/domain/services/treatment_query_models.dart';

void main() {
  test(
    'BarIA port exposes only minimized aggregates and explicit coverage',
    () async {
      final now = DateTime.utc(2026, 7, 21, 12);
      const service = _Query();

      final context = await QueryServiceBariaTreatmentContextPort(
        () async => service,
      ).load(now);

      expect(context.pendingToday, 1);
      expect(context.todayCoverage, AdherenceCoverageState.partial);
      expect(context.week.formulaVersion, 'treatment-adherence-v1');
      expect(context.generatedAt, now);
    },
  );
}

class _Query implements TreatmentAdherenceQueryService {
  const _Query();

  @override
  Future<TreatmentAdherenceSummary> summary(
    DateTime start,
    DateTime end,
  ) async => const TreatmentAdherenceSummary(
    eligible: 2,
    taken: 1,
    takenOnTime: 1,
    skipped: 0,
    missed: 1,
    coverage: .5,
    coverageState: AdherenceCoverageState.partial,
    origin: TreatmentDataOrigin.smartRoutines,
  );

  @override
  Future<TodayTreatmentReadModel> today(DateTime date) async =>
      TodayTreatmentReadModel(
        date: date,
        occurrences: [
          TodayTreatmentOccurrence(
            id: 'occurrence',
            routineId: 'routine',
            category: RoutineCategory.medication,
            title: 'not exposed by the port',
            scheduledFor: date,
            windowEndsAt: date.add(const Duration(hours: 1)),
            state: OccurrenceAdherenceState.pending,
            operationalState: TreatmentOccurrenceState.open,
          ),
        ],
        adherence: const TreatmentAdherenceSummary(
          eligible: 0,
          taken: 0,
          takenOnTime: 0,
          skipped: 0,
          missed: 0,
          coverage: .5,
          coverageState: AdherenceCoverageState.partial,
          origin: TreatmentDataOrigin.smartRoutines,
        ),
      );

  @override
  Future<Map<String, TodayTreatmentReadModel>> days(
    DateTime start,
    DateTime end,
  ) async => {};
}
