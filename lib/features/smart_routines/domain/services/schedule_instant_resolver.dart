import 'package:timezone/timezone.dart' as tz;

import '../enums/routine_enums.dart';
import '../value_objects/local_date.dart';
import '../value_objects/routine_values.dart';

final class ResolvedLocalScheduleTime {
  const ResolvedLocalScheduleTime({
    required this.instantUtc,
    required this.timeZone,
    required this.offset,
    required this.state,
    required this.requestedDate,
    required this.requestedTime,
    required this.resolvedDate,
    required this.resolvedTime,
    required this.diagnostic,
  });

  final DateTime instantUtc;
  final IanaTimeZone timeZone;
  final Duration offset;
  final ScheduleInstantResolutionState state;
  final LocalDate requestedDate;
  final TimeOfDayValue requestedTime;
  final LocalDate resolvedDate;
  final TimeOfDayValue resolvedTime;
  final String? diagnostic;
}

final class ScheduleInstantResolutionResult {
  const ScheduleInstantResolutionResult._({this.value, this.failure});
  const ScheduleInstantResolutionResult.resolved(
    ResolvedLocalScheduleTime value,
  ) : this._(value: value);
  const ScheduleInstantResolutionResult.failed(
    ScheduleInstantResolutionFailure failure,
  ) : this._(failure: failure);

  final ResolvedLocalScheduleTime? value;
  final ScheduleInstantResolutionFailure? failure;
  bool get isResolved => value != null;
}

/// Resolves wall-clock intent without consulting the device timezone or clock.
final class ScheduleInstantResolver {
  const ScheduleInstantResolver();

  ScheduleInstantResolutionResult resolve({
    required LocalDate localDate,
    required TimeOfDayValue localTime,
    required IanaTimeZone timeZone,
    NonexistentLocalTimePolicy nonexistentPolicy =
        NonexistentLocalTimePolicy.shiftForward,
    AmbiguousLocalTimePolicy ambiguousPolicy =
        AmbiguousLocalTimePolicy.earlierOccurrence,
  }) {
    final tz.Location location;
    try {
      location = timeZone.value == 'UTC'
          ? tz.UTC
          : tz.getLocation(timeZone.value);
    } on tz.LocationNotFoundException {
      return const ScheduleInstantResolutionResult.failed(
        ScheduleInstantResolutionFailure.invalidTimeZone,
      );
    }

    final requestedMinute = DateTime.utc(
      localDate.year,
      localDate.month,
      localDate.day,
      localTime.hour,
      localTime.minute,
    );
    var candidateMinute = requestedMinute;
    var candidates = _matchingInstants(location, candidateMinute);
    if (candidates.isEmpty) {
      if (nonexistentPolicy == NonexistentLocalTimePolicy.reject) {
        return const ScheduleInstantResolutionResult.failed(
          ScheduleInstantResolutionFailure.nonexistentLocalTimeRejected,
        );
      }
      do {
        candidateMinute = candidateMinute.add(const Duration(minutes: 1));
        candidates = _matchingInstants(location, candidateMinute);
      } while (candidates.isEmpty);
    }
    if (candidates.length > 1 &&
        ambiguousPolicy == AmbiguousLocalTimePolicy.reject) {
      return const ScheduleInstantResolutionResult.failed(
        ScheduleInstantResolutionFailure.ambiguousLocalTimeRejected,
      );
    }

    candidates.sort();
    final instant = candidates.first;
    final resolvedLocal = tz.TZDateTime.from(instant, location);
    final shifted = candidateMinute != requestedMinute;
    final ambiguous = candidates.length > 1;
    return ScheduleInstantResolutionResult.resolved(
      ResolvedLocalScheduleTime(
        instantUtc: instant,
        timeZone: timeZone,
        offset: resolvedLocal.timeZoneOffset,
        state: shifted
            ? ScheduleInstantResolutionState.shiftedForward
            : ambiguous
            ? ScheduleInstantResolutionState.ambiguousEarlierOffset
            : ScheduleInstantResolutionState.exact,
        requestedDate: localDate,
        requestedTime: localTime,
        resolvedDate: LocalDate.fromDateTime(resolvedLocal),
        resolvedTime: TimeOfDayValue(
          hour: resolvedLocal.hour,
          minute: resolvedLocal.minute,
        ),
        diagnostic: shifted
            ? 'nonexistent_local_time_shifted_forward'
            : ambiguous
            ? 'ambiguous_local_time_earlier_occurrence'
            : null,
      ),
    );
  }

  List<DateTime> _matchingInstants(tz.Location location, DateTime localMinute) {
    final matches = <DateTime>[];
    final start = localMinute.subtract(const Duration(hours: 26));
    final end = localMinute.add(const Duration(hours: 26));
    for (
      var instant = start;
      !instant.isAfter(end);
      instant = instant.add(const Duration(minutes: 1))
    ) {
      final local = tz.TZDateTime.from(instant, location);
      if (local.year == localMinute.year &&
          local.month == localMinute.month &&
          local.day == localMinute.day &&
          local.hour == localMinute.hour &&
          local.minute == localMinute.minute) {
        matches.add(instant);
      }
    }
    return matches;
  }
}
