enum RoutineCategory { medication, vitamin, supplement, other }

enum RoutineStatus { active, paused, completed, canceled, archived }

enum ScheduleFrequencyType {
  dailyAtTimes,
  specificWeekdaysAtTimes,
  everyNHours,
  everyNDays,
  weekly,
  monthly,
  singleDose,
  freeForm,
  asNeeded,
}

enum AdherenceEventType { taken, skipped, rescheduled, canceled, correction }

enum RoutineSource {
  manual,
  prescription,
  legacyMedication,
  legacyVitamin,
  imported,
  unknown,
}

enum PlanDurationType { fixed, continuous, unknown }

enum RoutinePlanMode { scheduled, asNeeded }

enum RoutineReminderPreference { disabled, enabled }

enum RoutineOccurrenceStatus {
  expected,
  rescheduled,
  canceled,
  paused,
  notApplicable,
}

enum RoutineOccurrenceOrigin { generated, adHocAsNeeded, migrated }

enum NonexistentLocalTimePolicy { shiftForward, reject }

enum AmbiguousLocalTimePolicy { earlierOccurrence, reject }

enum ScheduleInstantResolutionState {
  exact,
  shiftedForward,
  ambiguousEarlierOffset,
}

enum ScheduleInstantResolutionFailure {
  invalidTimeZone,
  nonexistentLocalTimeRejected,
  ambiguousLocalTimeRejected,
}

enum OccurrenceMaterializationFailure {
  temporalResolution,
  missingWindowDefinition,
  invalidWindow,
  identityFailure,
  inconsistentBlueprint,
}

enum AdherenceEventActor { user, caregiver, system, imported }

enum RoutinePauseScope { routine, plan }

enum ExpectationKind {
  recurringExpectation,
  singleExpectation,
  asNeeded,
  unstructured,
  unsupported,
  none,
}
