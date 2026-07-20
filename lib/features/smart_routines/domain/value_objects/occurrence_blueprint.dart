import '../enums/routine_enums.dart';
import '../errors/smart_routine_validation_exception.dart';
import 'local_date.dart';
import 'routine_values.dart';
import 'typed_ids.dart';

final class OccurrenceBlueprintLogicalKey {
  const OccurrenceBlueprintLogicalKey({
    required this.routineId,
    required this.planId,
    required this.scheduleId,
    required this.clinicalDate,
    required this.localTime,
    required this.sequence,
  });

  final RoutineId routineId;
  final RoutinePlanId planId;
  final RoutineScheduleId scheduleId;
  final LocalDate clinicalDate;
  final TimeOfDayValue localTime;
  final int sequence;

  @override
  bool operator ==(Object other) =>
      other is OccurrenceBlueprintLogicalKey &&
      routineId == other.routineId &&
      planId == other.planId &&
      scheduleId == other.scheduleId &&
      clinicalDate == other.clinicalDate &&
      localTime == other.localTime &&
      sequence == other.sequence;

  @override
  int get hashCode => Object.hash(
    routineId,
    planId,
    scheduleId,
    clinicalDate,
    localTime,
    sequence,
  );
}

/// Local clinical intent before timezone resolution or occurrence identity.
final class OccurrenceBlueprint implements Comparable<OccurrenceBlueprint> {
  factory OccurrenceBlueprint({
    required RoutineId routineId,
    required RoutinePlanId planId,
    required RoutineScheduleId scheduleId,
    required LocalDate clinicalDate,
    required TimeOfDayValue localTime,
    required IanaTimeZone timeZone,
    required ExpectationKind expectationKind,
    required int sequence,
    required LocalDate originalLocalDate,
    required TimeOfDayValue originalLocalTime,
    required ScheduleFrequencyType sourceRuleType,
    required int scheduleDisplayOrder,
  }) {
    if (sequence < 0) {
      throw const SmartRoutineValidationException(
        'invalid_blueprint_sequence',
        'Blueprint sequence cannot be negative.',
      );
    }
    if (scheduleDisplayOrder < 0) {
      throw const SmartRoutineValidationException(
        'invalid_blueprint_display_order',
        'Blueprint schedule display order cannot be negative.',
      );
    }
    if (expectationKind != ExpectationKind.recurringExpectation &&
        expectationKind != ExpectationKind.singleExpectation) {
      throw const SmartRoutineValidationException(
        'invalid_blueprint_expectation_kind',
        'Blueprint requires a structured expectation kind.',
      );
    }
    return OccurrenceBlueprint._(
      routineId: routineId,
      planId: planId,
      scheduleId: scheduleId,
      clinicalDate: clinicalDate,
      localTime: localTime,
      timeZone: timeZone,
      expectationKind: expectationKind,
      sequence: sequence,
      originalLocalDate: originalLocalDate,
      originalLocalTime: originalLocalTime,
      sourceRuleType: sourceRuleType,
      scheduleDisplayOrder: scheduleDisplayOrder,
    );
  }

  const OccurrenceBlueprint._({
    required this.routineId,
    required this.planId,
    required this.scheduleId,
    required this.clinicalDate,
    required this.localTime,
    required this.timeZone,
    required this.expectationKind,
    required this.sequence,
    required this.originalLocalDate,
    required this.originalLocalTime,
    required this.sourceRuleType,
    required this.scheduleDisplayOrder,
  });

  final RoutineId routineId;
  final RoutinePlanId planId;
  final RoutineScheduleId scheduleId;
  final LocalDate clinicalDate;
  final TimeOfDayValue localTime;
  final IanaTimeZone timeZone;
  final ExpectationKind expectationKind;
  final int sequence;
  final LocalDate originalLocalDate;
  final TimeOfDayValue originalLocalTime;
  final ScheduleFrequencyType sourceRuleType;
  final int scheduleDisplayOrder;

  OccurrenceBlueprintLogicalKey get logicalKey => OccurrenceBlueprintLogicalKey(
    routineId: routineId,
    planId: planId,
    scheduleId: scheduleId,
    clinicalDate: clinicalDate,
    localTime: localTime,
    sequence: sequence,
  );

  @override
  int compareTo(OccurrenceBlueprint other) {
    final date = clinicalDate.compareTo(other.clinicalDate);
    if (date != 0) return date;
    final time = localTime.compareTo(other.localTime);
    if (time != 0) return time;
    final order = scheduleDisplayOrder.compareTo(other.scheduleDisplayOrder);
    if (order != 0) return order;
    final schedule = scheduleId.value.compareTo(other.scheduleId.value);
    if (schedule != 0) return schedule;
    return sequence.compareTo(other.sequence);
  }

  @override
  bool operator ==(Object other) =>
      other is OccurrenceBlueprint &&
      logicalKey == other.logicalKey &&
      timeZone == other.timeZone &&
      expectationKind == other.expectationKind &&
      originalLocalDate == other.originalLocalDate &&
      originalLocalTime == other.originalLocalTime &&
      sourceRuleType == other.sourceRuleType &&
      scheduleDisplayOrder == other.scheduleDisplayOrder;

  @override
  int get hashCode => Object.hash(
    logicalKey,
    timeZone,
    expectationKind,
    originalLocalDate,
    originalLocalTime,
    sourceRuleType,
    scheduleDisplayOrder,
  );
}
