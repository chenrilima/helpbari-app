import '../../../smart_routines/domain/services/treatment_query_models.dart';
import '../../../smart_routines/domain/enums/routine_enums.dart';

class BariaTreatmentContext {
  const BariaTreatmentContext({
    required this.pendingToday,
    required this.todayCoverage,
    required this.week,
    required this.month,
    required this.generatedAt,
  });
  final int pendingToday;
  final AdherenceCoverageState todayCoverage;
  final TreatmentAdherenceSummary week;
  final TreatmentAdherenceSummary month;
  final DateTime generatedAt;
}

abstract interface class BariaTreatmentContextPort {
  Future<BariaTreatmentContext> load(DateTime now);
}

class QueryServiceBariaTreatmentContextPort
    implements BariaTreatmentContextPort {
  const QueryServiceBariaTreatmentContextPort(this.query);
  final Future<TreatmentAdherenceQueryService> Function() query;

  @override
  Future<BariaTreatmentContext> load(DateTime now) async {
    final service = await query();
    final day = DateTime(now.year, now.month, now.day);
    final today = await service.today(day);
    return BariaTreatmentContext(
      pendingToday: today.open.length,
      todayCoverage: today.adherence.coverageState,
      week: await service.summary(day.subtract(const Duration(days: 6)), day),
      month: await service.summary(day.subtract(const Duration(days: 29)), day),
      generatedAt: now,
    );
  }
}
