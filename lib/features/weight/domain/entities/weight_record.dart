import '../../../../core/domain/entity.dart';
import '../value_objects/value_objects.dart';

class WeightRecord extends Entity {
  const WeightRecord({
    required this.id,
    required this.weight,
    required this.recordedAt,
    this.notes,
  });

  @override
  final String id;

  final WeightValue weight;

  final RecordedAt recordedAt;

  final Notes? notes;

  bool get hasNotes => notes != null && notes!.isNotEmpty;

  bool get wasRecordedToday => recordedAt.isToday;

  String get formattedWeight => weight.formatted;
}
