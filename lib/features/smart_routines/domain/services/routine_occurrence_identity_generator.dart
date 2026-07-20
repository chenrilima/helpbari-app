import 'package:uuid/uuid.dart';

import '../value_objects/occurrence_blueprint.dart';
import '../value_objects/typed_ids.dart';

/// UUIDv5 contract: UTF-8 of
/// `v1|routine:<id>|plan:<id>|schedule:<id>|date:<yyyy-MM-dd>|time:<HH:mm:00>`
/// `|tz:<iana>|seq:<n>` under the HelpBari occurrence-only namespace.
final class RoutineOccurrenceIdentityGenerator {
  const RoutineOccurrenceIdentityGenerator();

  static const schemaVersion = 'v1';
  static const namespace = 'f45b7f48-8f4d-5c67-9d7e-6bc0f7f8345b';
  static const Uuid _uuid = Uuid();

  String canonicalName(OccurrenceBlueprint blueprint) =>
      '$schemaVersion|routine:${blueprint.routineId.value}'
      '|plan:${blueprint.planId.value}'
      '|schedule:${blueprint.scheduleId.value}'
      '|date:${blueprint.originalLocalDate}'
      '|time:${blueprint.originalLocalTime}:00'
      '|tz:${blueprint.timeZone.value}'
      '|seq:${blueprint.sequence}';

  RoutineOccurrenceId generate(OccurrenceBlueprint blueprint) =>
      RoutineOccurrenceId(_uuid.v5(namespace, canonicalName(blueprint)));
}
