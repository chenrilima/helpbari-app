import '../../../../core/domain/entity.dart';
import '../enums/routine_enums.dart';
import '../errors/smart_routine_validation_exception.dart';
import '../value_objects/routine_values.dart';
import '../value_objects/schedule_rule.dart';
import '../value_objects/typed_ids.dart';
import 'routine_plan.dart';

final class RoutineSchedule extends Entity {
  factory RoutineSchedule({
    required RoutineScheduleId scheduleId,
    required RoutinePlan plan,
    required ScheduleRule rule,
    required IanaTimeZone timeZone,
    required RoutineReminderPreference reminderPreference,
    required Duration earlyTolerance,
    required Duration onTimeTolerance,
    required Duration lateTolerance,
    required bool isEnabled,
    required int displayOrder,
  }) {
    plan.ensureCompatibleRule(rule);
    if (earlyTolerance.isNegative ||
        onTimeTolerance.isNegative ||
        lateTolerance.isNegative) {
      throw const SmartRoutineValidationException(
        'negative_schedule_tolerance',
        'Schedule tolerances cannot be negative.',
      );
    }
    if (displayOrder < 0) {
      throw const SmartRoutineValidationException(
        'invalid_schedule_order',
        'Schedule display order cannot be negative.',
      );
    }
    return RoutineSchedule._(
      scheduleId: scheduleId,
      planId: plan.planId,
      rule: rule,
      timeZone: timeZone,
      reminderPreference: reminderPreference,
      earlyTolerance: earlyTolerance,
      onTimeTolerance: onTimeTolerance,
      lateTolerance: lateTolerance,
      isEnabled: isEnabled,
      displayOrder: displayOrder,
    );
  }

  const RoutineSchedule._({
    required this.scheduleId,
    required this.planId,
    required this.rule,
    required this.timeZone,
    required this.reminderPreference,
    required this.earlyTolerance,
    required this.onTimeTolerance,
    required this.lateTolerance,
    required this.isEnabled,
    required this.displayOrder,
  });

  final RoutineScheduleId scheduleId;
  @override
  String get id => scheduleId.value;
  final RoutinePlanId planId;
  final ScheduleRule rule;
  final IanaTimeZone timeZone;
  final RoutineReminderPreference reminderPreference;
  final Duration earlyTolerance;
  final Duration onTimeTolerance;
  final Duration lateTolerance;
  final bool isEnabled;
  final int displayOrder;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutineSchedule &&
          scheduleId == other.scheduleId &&
          planId == other.planId &&
          rule == other.rule &&
          timeZone == other.timeZone &&
          reminderPreference == other.reminderPreference &&
          earlyTolerance == other.earlyTolerance &&
          onTimeTolerance == other.onTimeTolerance &&
          lateTolerance == other.lateTolerance &&
          isEnabled == other.isEnabled &&
          displayOrder == other.displayOrder;

  @override
  int get hashCode => Object.hash(
    scheduleId,
    planId,
    rule,
    timeZone,
    reminderPreference,
    earlyTolerance,
    onTimeTolerance,
    lateTolerance,
    isEnabled,
    displayOrder,
  );
}
