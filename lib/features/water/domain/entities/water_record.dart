import '../../../../core/domain/entity.dart';
import '../value_objects/value_objects.dart';

class WaterRecord extends Entity {
  const WaterRecord({
    required this.id,
    required this.amount,
    required this.recordedAt,
  });

  @override
  final String id;

  final WaterAmount amount;

  final DateTime recordedAt;

  bool get wasRecordedToday {
    final now = DateTime.now();

    return now.year == recordedAt.year &&
        now.month == recordedAt.month &&
        now.day == recordedAt.day;
  }

  String get formattedAmount => amount.formatted;
}
