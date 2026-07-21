import '../../../smart_routines/domain/services/treatment_query_models.dart';

class BariaTreatmentContext {
  const BariaTreatmentContext({
    required this.today,
    required this.week,
    required this.month,
  });
  final TodayTreatmentReadModel today;
  final TreatmentAdherenceSummary week;
  final TreatmentAdherenceSummary month;
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
    return BariaTreatmentContext(
      today: await service.today(day),
      week: await service.summary(day.subtract(const Duration(days: 6)), day),
      month: await service.summary(day.subtract(const Duration(days: 29)), day),
    );
  }
}
