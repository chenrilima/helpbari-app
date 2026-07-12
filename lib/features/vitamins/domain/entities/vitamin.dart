import '../../../../core/domain/entity.dart';
import '../value_objects/value_objects.dart';

class Vitamin extends Entity {
  const Vitamin({
    required this.id,
    required this.name,
    required this.scheduleTime,
  });

  @override
  final String id;

  final VitaminName name;
  final VitaminScheduleTime scheduleTime;
  String get formattedName => name.value;

  String get formattedTime => scheduleTime.formatted;

  Vitamin copyWith({VitaminName? name, VitaminScheduleTime? scheduleTime}) {
    return Vitamin(
      id: id,
      name: name ?? this.name,
      scheduleTime: scheduleTime ?? this.scheduleTime,
    );
  }
}
