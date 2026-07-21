import '../enums/routine_enums.dart';

enum TreatmentDataOrigin { legacy, smartRoutines, mixed }

enum TreatmentOccurrenceState {
  future,
  due,
  open,
  resolved,
  missed,
  canceled,
  requiresReview,
}

class TreatmentAdherenceSummary {
  const TreatmentAdherenceSummary({
    required this.eligible,
    required this.taken,
    required this.takenOnTime,
    required this.skipped,
    required this.missed,
    required this.coverage,
    required this.coverageState,
    required this.origin,
    this.byCategory = const <RoutineCategory, TreatmentAdherenceSummary>{},
    this.formulaVersion = 'treatment-adherence-v1',
  });
  final int eligible;
  final int taken;
  final int takenOnTime;
  final int skipped;
  final int missed;
  final double coverage;
  final AdherenceCoverageState coverageState;
  final TreatmentDataOrigin origin;
  final Map<RoutineCategory, TreatmentAdherenceSummary> byCategory;
  final String formulaVersion;
  double? get adherence => eligible == 0 ? null : taken / eligible;
  double? get onTimeAdherence => eligible == 0 ? null : takenOnTime / eligible;
}

class TodayTreatmentOccurrence {
  const TodayTreatmentOccurrence({
    required this.id,
    required this.routineId,
    required this.category,
    required this.title,
    required this.scheduledFor,
    required this.windowEndsAt,
    required this.state,
    required this.operationalState,
    this.originalScheduledFor,
  });
  final String id;
  final String routineId;
  final RoutineCategory category;
  final String title;
  final DateTime scheduledFor;
  final DateTime windowEndsAt;
  final OccurrenceAdherenceState state;
  final TreatmentOccurrenceState operationalState;
  final DateTime? originalScheduledFor;
}

class TodayTreatmentReadModel {
  const TodayTreatmentReadModel({
    required this.date,
    required this.occurrences,
    required this.adherence,
  });
  final DateTime date;
  final List<TodayTreatmentOccurrence> occurrences;
  final TreatmentAdherenceSummary adherence;
  List<TodayTreatmentOccurrence> get open => occurrences
      .where((value) => value.state == OccurrenceAdherenceState.pending)
      .toList(growable: false);
  int pendingFor(RoutineCategory category) =>
      open.where((value) => value.category == category).length;
  TreatmentAdherenceSummary? adherenceFor(RoutineCategory category) =>
      adherence.byCategory[category];
}

abstract interface class TreatmentAdherenceQueryService {
  Future<TreatmentAdherenceSummary> summary(DateTime start, DateTime end);
  Future<TodayTreatmentReadModel> today(DateTime date);
  Future<Map<String, TodayTreatmentReadModel>> days(
    DateTime start,
    DateTime end,
  );
}
