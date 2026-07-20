import 'dart:collection';

import '../entities/entities.dart';
import '../enums/routine_enums.dart';
import '../errors/smart_routine_validation_exception.dart';
import '../value_objects/routine_values.dart';

final class RoutineAdherenceProjection {
  RoutineAdherenceProjection({
    required this.state,
    required this.effectiveWindow,
    required this.effectiveEvent,
    required Iterable<RoutineAdherenceEvent> effectiveTimeline,
    required Iterable<RoutineAdherenceEvent> ignoredEvents,
    required Iterable<RoutineAdherenceEvent> supersededEvents,
    required Iterable<AdherenceProjectionDiagnostic> diagnostics,
    required this.delay,
    required this.isPrn,
    required this.isExcluded,
  }) : effectiveTimeline = List.unmodifiable(effectiveTimeline),
       ignoredEvents = List.unmodifiable(ignoredEvents),
       supersededEvents = List.unmodifiable(supersededEvents),
       diagnostics = Set.unmodifiable(diagnostics);

  final OccurrenceAdherenceState state;
  final OccurrenceWindow effectiveWindow;
  final RoutineAdherenceEvent? effectiveEvent;
  final List<RoutineAdherenceEvent> effectiveTimeline;
  final List<RoutineAdherenceEvent> ignoredEvents;
  final List<RoutineAdherenceEvent> supersededEvents;
  final Set<AdherenceProjectionDiagnostic> diagnostics;
  final Duration? delay;
  final bool isPrn;
  final bool isExcluded;
  bool get isInconsistent => state == OccurrenceAdherenceState.inconsistent;
  UnmodifiableListView<RoutineAdherenceEvent> get timeline =>
      UnmodifiableListView(effectiveTimeline);
}

final class RoutineAdherenceProjector {
  const RoutineAdherenceProjector();

  RoutineAdherenceProjection project({
    required RoutineOccurrence occurrence,
    required Iterable<RoutineAdherenceEvent> events,
    required DateTime evaluatedAtUtc,
    Iterable<RoutinePause> pauses = const [],
  }) {
    if (!evaluatedAtUtc.isUtc) {
      throw const SmartRoutineValidationException(
        'adherence_evaluation_requires_utc',
        'evaluatedAtUtc must be UTC.',
      );
    }
    final input = events.toList()..sort(_compareEvents);
    final diagnostics = <AdherenceProjectionDiagnostic>{};
    final ignored = <RoutineAdherenceEvent>[];
    final byId = <String, RoutineAdherenceEvent>{};
    for (final event in input) {
      if (!_belongsTo(event, occurrence)) {
        diagnostics.add(AdherenceProjectionDiagnostic.foreignEvent);
        ignored.add(event);
        continue;
      }
      final existing = byId[event.id];
      if (existing != null) {
        diagnostics.add(AdherenceProjectionDiagnostic.duplicateEvent);
        ignored.add(event);
        continue;
      }
      byId[event.id] = event;
    }
    final ordered = byId.values.toList()..sort(_compareEvents);
    final corrections = ordered
        .where((event) => event.type == AdherenceEventType.correction)
        .toList();
    final children = <String, List<RoutineAdherenceEvent>>{};
    for (final correction in corrections) {
      final reference = correction.referencedEventId!.value;
      if (!byId.containsKey(reference)) {
        diagnostics.add(
          AdherenceProjectionDiagnostic.missingCorrectionReference,
        );
        ignored.add(correction);
        continue;
      }
      children.putIfAbsent(reference, () => []).add(correction);
    }
    if (children.values.any((values) => values.length > 1)) {
      diagnostics.add(AdherenceProjectionDiagnostic.concurrentCorrections);
    }
    if (_hasCorrectionCycle(corrections, byId)) {
      diagnostics.add(AdherenceProjectionDiagnostic.correctionCycle);
    }
    if (_fatal(diagnostics)) {
      return _result(
        occurrence: occurrence,
        state: OccurrenceAdherenceState.inconsistent,
        effectiveWindow: occurrence.currentWindow,
        ignored: ignored,
        superseded: const [],
        timeline: ordered,
        diagnostics: diagnostics,
      );
    }

    final supersededIds = corrections
        .where((event) => !ignored.contains(event))
        .map((event) => event.referencedEventId!.value)
        .toSet();
    final superseded = ordered
        .where((event) => supersededIds.contains(event.id))
        .toList();
    final effective = <_EffectiveEvent>[];
    for (final event in ordered) {
      if (supersededIds.contains(event.id) || ignored.contains(event)) continue;
      if (event.effectiveAtUtc.isAfter(evaluatedAtUtc)) {
        ignored.add(event);
        continue;
      }
      if (event.type != AdherenceEventType.correction) {
        effective.add(_EffectiveEvent.fromEvent(event));
      } else if (event.correctionAction == AdherenceCorrectionAction.replace) {
        effective.add(_EffectiveEvent.fromCorrection(event));
      }
    }
    effective.sort((left, right) => _compareEvents(left.source, right.source));
    final terminal = effective
        .where(
          (item) =>
              item.type == AdherenceEventType.taken ||
              item.type == AdherenceEventType.skipped ||
              item.type == AdherenceEventType.canceled,
        )
        .toList();
    if (terminal.length > 1) {
      diagnostics.add(AdherenceProjectionDiagnostic.conflictingTerminalEvents);
    }
    final reschedules = effective
        .where((item) => item.type == AdherenceEventType.rescheduled)
        .toList();
    if (terminal.isNotEmpty &&
        reschedules.any(
          (item) => item.occurredAtUtc.isAfter(terminal.first.occurredAtUtc),
        )) {
      diagnostics.add(AdherenceProjectionDiagnostic.rescheduleAfterTerminal);
    }
    if (_fatal(diagnostics)) {
      return _result(
        occurrence: occurrence,
        state: OccurrenceAdherenceState.inconsistent,
        effectiveWindow: occurrence.currentWindow,
        ignored: ignored,
        superseded: superseded,
        timeline: effective.map((item) => item.source),
        diagnostics: diagnostics,
      );
    }

    final effectiveWindow = reschedules.isEmpty
        ? occurrence.currentWindow
        : reschedules.last.window!;
    final isPrn =
        occurrence.origin == RoutineOccurrenceOrigin.adHocAsNeeded ||
        occurrence.expectationKind == ExpectationKind.asNeeded;
    final explicitlyExcluded = {
      RoutineOccurrenceStatus.paused,
      RoutineOccurrenceStatus.canceled,
      RoutineOccurrenceStatus.notApplicable,
    }.contains(occurrence.status);
    final paused = _isPaused(occurrence, pauses, effectiveWindow.scheduledFor);
    if (paused && terminal.isNotEmpty) {
      diagnostics.add(AdherenceProjectionDiagnostic.retroactivePause);
    }
    if (explicitlyExcluded || (paused && terminal.isEmpty)) {
      return _result(
        occurrence: occurrence,
        state: OccurrenceAdherenceState.notApplicable,
        effectiveWindow: effectiveWindow,
        effectiveEvent: terminal.firstOrNull?.source,
        ignored: ignored,
        superseded: superseded,
        timeline: effective.map((item) => item.source),
        diagnostics: diagnostics,
        isPrn: isPrn,
        isExcluded: true,
      );
    }
    if (terminal.isEmpty) {
      return _result(
        occurrence: occurrence,
        state: isPrn
            ? OccurrenceAdherenceState.notApplicable
            : evaluatedAtUtc.isBefore(effectiveWindow.windowEndsAt)
            ? OccurrenceAdherenceState.pending
            : OccurrenceAdherenceState.missed,
        effectiveWindow: effectiveWindow,
        ignored: ignored,
        superseded: superseded,
        timeline: effective.map((item) => item.source),
        diagnostics: diagnostics,
        isPrn: isPrn,
        isExcluded: isPrn,
      );
    }
    final selected = terminal.single;
    if (selected.type == AdherenceEventType.canceled) {
      return _result(
        occurrence: occurrence,
        state: OccurrenceAdherenceState.notApplicable,
        effectiveWindow: effectiveWindow,
        effectiveEvent: selected.source,
        ignored: ignored,
        superseded: superseded,
        timeline: effective.map((item) => item.source),
        diagnostics: diagnostics,
        isPrn: isPrn,
        isExcluded: true,
      );
    }
    if (selected.type == AdherenceEventType.skipped) {
      return _result(
        occurrence: occurrence,
        state: OccurrenceAdherenceState.skipped,
        effectiveWindow: effectiveWindow,
        effectiveEvent: selected.source,
        ignored: ignored,
        superseded: superseded,
        timeline: effective.map((item) => item.source),
        diagnostics: diagnostics,
        isPrn: isPrn,
      );
    }
    final takenAt = selected.occurredAtUtc;
    final state = takenAt.isBefore(effectiveWindow.windowStartsAt)
        ? OccurrenceAdherenceState.takenEarly
        : !takenAt.isAfter(effectiveWindow.onTimeEndsAt)
        ? OccurrenceAdherenceState.takenOnTime
        : OccurrenceAdherenceState.takenLate;
    return _result(
      occurrence: occurrence,
      state: state,
      effectiveWindow: effectiveWindow,
      effectiveEvent: selected.source,
      ignored: ignored,
      superseded: superseded,
      timeline: effective.map((item) => item.source),
      diagnostics: diagnostics,
      delay: takenAt.difference(effectiveWindow.scheduledFor),
      isPrn: isPrn,
    );
  }

  bool _belongsTo(RoutineAdherenceEvent event, RoutineOccurrence occurrence) =>
      event.occurrenceId == occurrence.occurrenceId &&
      event.routineId == occurrence.routineId &&
      event.planId == occurrence.planId &&
      event.scheduleId == occurrence.scheduleId;

  bool _hasCorrectionCycle(
    List<RoutineAdherenceEvent> corrections,
    Map<String, RoutineAdherenceEvent> byId,
  ) {
    for (final start in corrections) {
      final seen = <String>{};
      RoutineAdherenceEvent? current = start;
      while (current?.type == AdherenceEventType.correction) {
        if (!seen.add(current!.id)) return true;
        current = byId[current.referencedEventId!.value];
      }
    }
    return false;
  }

  bool _fatal(Set<AdherenceProjectionDiagnostic> diagnostics) =>
      diagnostics.any(
        {
          AdherenceProjectionDiagnostic.duplicateEvent,
          AdherenceProjectionDiagnostic.missingCorrectionReference,
          AdherenceProjectionDiagnostic.correctionCycle,
          AdherenceProjectionDiagnostic.concurrentCorrections,
          AdherenceProjectionDiagnostic.conflictingTerminalEvents,
          AdherenceProjectionDiagnostic.rescheduleAfterTerminal,
        }.contains,
      );

  bool _isPaused(
    RoutineOccurrence occurrence,
    Iterable<RoutinePause> pauses,
    DateTime at,
  ) => pauses.any(
    (pause) =>
        pause.routineId == occurrence.routineId &&
        (pause.scope == RoutinePauseScope.routine ||
            pause.planId == occurrence.planId) &&
        !at.isBefore(pause.startsAt) &&
        (pause.endsAt == null || at.isBefore(pause.endsAt!)),
  );

  RoutineAdherenceProjection _result({
    required RoutineOccurrence occurrence,
    required OccurrenceAdherenceState state,
    required OccurrenceWindow effectiveWindow,
    required Iterable<RoutineAdherenceEvent> ignored,
    required Iterable<RoutineAdherenceEvent> superseded,
    required Iterable<RoutineAdherenceEvent> timeline,
    required Iterable<AdherenceProjectionDiagnostic> diagnostics,
    RoutineAdherenceEvent? effectiveEvent,
    Duration? delay,
    bool? isPrn,
    bool isExcluded = false,
  }) => RoutineAdherenceProjection(
    state: state,
    effectiveWindow: effectiveWindow,
    effectiveEvent: effectiveEvent,
    effectiveTimeline: timeline,
    ignoredEvents: ignored,
    supersededEvents: superseded,
    diagnostics: diagnostics,
    delay: delay,
    isPrn:
        isPrn ??
        occurrence.origin == RoutineOccurrenceOrigin.adHocAsNeeded ||
            occurrence.expectationKind == ExpectationKind.asNeeded,
    isExcluded: isExcluded,
  );

  int _compareEvents(RoutineAdherenceEvent left, RoutineAdherenceEvent right) {
    final effective = left.effectiveAtUtc.compareTo(right.effectiveAtUtc);
    if (effective != 0) return effective;
    final recorded = left.recordedAtUtc.compareTo(right.recordedAtUtc);
    if (recorded != 0) return recorded;
    final id = left.eventId.value.compareTo(right.eventId.value);
    if (id != 0) return id;
    final type = left.type.index.compareTo(right.type.index);
    if (type != 0) return type;
    final action = (left.correctionAction?.index ?? -1).compareTo(
      right.correctionAction?.index ?? -1,
    );
    if (action != 0) return action;
    final replacement = (left.replacementType?.index ?? -1).compareTo(
      right.replacementType?.index ?? -1,
    );
    if (replacement != 0) return replacement;
    return (left.note ?? '').compareTo(right.note ?? '');
  }
}

final class _EffectiveEvent {
  const _EffectiveEvent({
    required this.source,
    required this.type,
    required this.occurredAtUtc,
    this.window,
  });
  factory _EffectiveEvent.fromEvent(RoutineAdherenceEvent event) =>
      _EffectiveEvent(
        source: event,
        type: event.type,
        occurredAtUtc: event.occurredAtUtc,
        window: event.rescheduledWindow,
      );
  factory _EffectiveEvent.fromCorrection(RoutineAdherenceEvent event) =>
      _EffectiveEvent(
        source: event,
        type: event.replacementType!,
        occurredAtUtc: event.replacementOccurredAtUtc ?? event.occurredAtUtc,
        window: event.rescheduledWindow,
      );
  final RoutineAdherenceEvent source;
  final AdherenceEventType type;
  final DateTime occurredAtUtc;
  final OccurrenceWindow? window;
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
