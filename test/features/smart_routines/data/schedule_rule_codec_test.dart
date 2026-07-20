import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/time/iana_timezone_bootstrap.dart';
import 'package:helpbari/features/smart_routines/data/dtos/smart_routine_dtos.dart';
import 'package:helpbari/features/smart_routines/domain/smart_routines_domain.dart';
import 'package:timezone/timezone.dart' as timezone;

void main() {
  const codec = ScheduleRuleCodec();
  final time = TimeOfDayValue(hour: 8, minute: 30);

  test('round-trips cadence anchors without timezone conversion', () {
    final rules = <ScheduleRule>[
      EveryNHoursRule(8, anchorAtUtc: DateTime.utc(2026, 7, 20, 10)),
      EveryNDaysRule(
        intervalDays: 3,
        anchorDate: LocalDate(year: 2026, month: 7, day: 20),
        times: [time],
      ),
    ];

    for (final rule in rules) {
      expect(codec.decode(codec.encode(rule)), rule);
    }
  });

  test('rejects unknown schema and rule types', () {
    expect(
      () => codec.fromJson({'schemaVersion': 2, 'type': 'asNeeded'}),
      throwsFormatException,
    );
    expect(
      () => codec.fromJson({'schemaVersion': 1, 'type': 'futureRule'}),
      throwsFormatException,
    );
  });

  test('IANA bootstrap is idempotent and does not require timezone.local', () {
    IanaTimezoneBootstrap.initialize();
    IanaTimezoneBootstrap.initialize();

    expect(IanaTimezoneBootstrap.isInitialized, isTrue);
    expect(timezone.getLocation('America/Sao_Paulo').name, 'America/Sao_Paulo');
  });
}
