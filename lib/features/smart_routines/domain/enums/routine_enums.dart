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

enum AdherenceCorrectionAction { invalidate, replace }

enum OccurrenceAdherenceState {
  pending,
  takenEarly,
  takenOnTime,
  takenLate,
  skipped,
  missed,
  notApplicable,
  inconsistent,
}

enum AdherenceProjectionDiagnostic {
  duplicateEvent,
  foreignEvent,
  missingCorrectionReference,
  correctionCycle,
  concurrentCorrections,
  incompatibleCorrection,
  conflictingTerminalEvents,
  rescheduleAfterTerminal,
  inconsistentReschedule,
  retroactivePause,
  insufficientData,
  duplicateOccurrence,
  missingCategory,
}

enum AdherenceMetricState { available, unavailable, inconsistent }

enum AdherenceCoverageState { complete, partial, unknown, notApplicable }

enum RoutineSource {
  manual,
  prescription,
  legacyMedication,
  legacyVitamin,
  imported,
  unknown,
}

enum PlanDurationType { bounded, continuous, unknown, singleDose }

enum RoutineTemporalPrecision {
  exact,
  inferredFromProfile,
  estimatedFromLegacyDate,
  unknown,
}

enum RoutinePlanOrigin { manual, migratedLegacy, prescriptionImport }

enum RoutineValidationStatus { confirmed, estimated, validationRequired }

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
