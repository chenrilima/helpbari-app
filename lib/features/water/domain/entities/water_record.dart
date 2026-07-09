import '../../../../core/domain/entity.dart';
import '../../../../core/services/clock_service.dart';
import '../value_objects/value_objects.dart';

class WaterRecord extends Entity {
  const WaterRecord({
    required this.id,
    required this.amount,
    required this.recordedAt,
    this.clock = const AppClockService(),
  });

  @override
  final String id;

  final WaterAmount amount;

  final DateTime recordedAt;

  final ClockService clock;

  bool get wasRecordedToday {
    final now = clock.now();

    return now.year == recordedAt.year &&
        now.month == recordedAt.month &&
        now.day == recordedAt.day;
  }

  String get formattedAmount => amount.formatted;
}
