import '../enums/routine_enums.dart';
import 'routine_adherence_projector.dart';

final class AdherenceCoverageResult {
  const AdherenceCoverageResult({
    required this.expectedCount,
    required this.evaluableCount,
    required this.excludedCount,
    required this.unavailableCount,
    required this.futureCount,
    required this.rate,
    required this.state,
  });
  final int expectedCount;
  final int evaluableCount;
  final int excludedCount;
  final int unavailableCount;
  final int futureCount;
  final double? rate;
  final AdherenceCoverageState state;
}

final class AdherenceCalculationResult {
  const AdherenceCalculationResult({
    required this.denominator,
    required this.adherentCount,
    required this.completedCount,
    required this.nonAdherentCount,
    required this.takenEarlyCount,
    required this.takenOnTimeCount,
    required this.takenLateCount,
    required this.skippedCount,
    required this.missedCount,
    required this.pendingCount,
    required this.excludedCount,
    required this.unavailableCount,
    required this.prnTakenCount,
    required this.prnUsageDays,
    required this.adherenceRate,
    required this.completionRate,
    required this.state,
    required this.coverage,
  });

  final int denominator;
  final int adherentCount;
  final int completedCount;
  final int nonAdherentCount;
  final int takenEarlyCount;
  final int takenOnTimeCount;
  final int takenLateCount;
  final int skippedCount;
  final int missedCount;
  final int pendingCount;
  final int excludedCount;
  final int unavailableCount;
  final int prnTakenCount;
  final int prnUsageDays;
  final double? adherenceRate;
  final double? completionRate;
  final AdherenceMetricState state;
  final AdherenceCoverageResult coverage;
}

final class AdherenceCalculator {
  const AdherenceCalculator();

  AdherenceCalculationResult calculate(
    Iterable<RoutineAdherenceProjection> projections,
  ) {
    final input = projections.toList();
    var early = 0;
    var onTime = 0;
    var late = 0;
    var skipped = 0;
    var missed = 0;
    var pending = 0;
    var excluded = 0;
    var unavailable = 0;
    var prnTaken = 0;
    final prnDays = <String>{};
    for (final projection in input) {
      if (projection.isPrn) {
        if ({
          OccurrenceAdherenceState.takenEarly,
          OccurrenceAdherenceState.takenOnTime,
          OccurrenceAdherenceState.takenLate,
        }.contains(projection.state)) {
          prnTaken++;
          final instant = projection.effectiveEvent!.effectiveAtUtc;
          prnDays.add('${instant.year}-${instant.month}-${instant.day}');
        }
        continue;
      }
      if (projection.isExcluded ||
          projection.state == OccurrenceAdherenceState.notApplicable) {
        excluded++;
        continue;
      }
      switch (projection.state) {
        case OccurrenceAdherenceState.takenEarly:
          early++;
        case OccurrenceAdherenceState.takenOnTime:
          onTime++;
        case OccurrenceAdherenceState.takenLate:
          late++;
        case OccurrenceAdherenceState.skipped:
          skipped++;
        case OccurrenceAdherenceState.missed:
          missed++;
        case OccurrenceAdherenceState.pending:
          pending++;
        case OccurrenceAdherenceState.inconsistent:
          unavailable++;
        case OccurrenceAdherenceState.notApplicable:
          excluded++;
      }
    }
    final denominator = early + onTime + late + skipped + missed;
    final adherent = early + onTime;
    final completed = adherent + late;
    final expected =
        input.length -
        excluded -
        input.where((projection) => projection.isPrn).length;
    final normalizedExpected = expected < 0 ? 0 : expected;
    final evaluable = normalizedExpected - unavailable;
    final coverageRate = normalizedExpected == 0
        ? null
        : evaluable / normalizedExpected;
    final coverageState = normalizedExpected == 0
        ? AdherenceCoverageState.notApplicable
        : unavailable == 0
        ? AdherenceCoverageState.complete
        : evaluable == 0
        ? AdherenceCoverageState.unknown
        : AdherenceCoverageState.partial;
    final metricState = denominator == 0
        ? unavailable > 0
              ? AdherenceMetricState.inconsistent
              : AdherenceMetricState.unavailable
        : AdherenceMetricState.available;
    return AdherenceCalculationResult(
      denominator: denominator,
      adherentCount: adherent,
      completedCount: completed,
      nonAdherentCount: denominator - adherent,
      takenEarlyCount: early,
      takenOnTimeCount: onTime,
      takenLateCount: late,
      skippedCount: skipped,
      missedCount: missed,
      pendingCount: pending,
      excludedCount: excluded,
      unavailableCount: unavailable,
      prnTakenCount: prnTaken,
      prnUsageDays: prnDays.length,
      adherenceRate: denominator == 0 ? null : adherent / denominator,
      completionRate: denominator == 0 ? null : completed / denominator,
      state: metricState,
      coverage: AdherenceCoverageResult(
        expectedCount: normalizedExpected,
        evaluableCount: evaluable,
        excludedCount: excluded,
        unavailableCount: unavailable,
        futureCount: pending,
        rate: coverageRate,
        state: coverageState,
      ),
    );
  }
}
