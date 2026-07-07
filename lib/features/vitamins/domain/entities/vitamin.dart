import '../../../../core/domain/entity.dart';
import '../value_objects/value_objects.dart';

class Vitamin extends Entity {
  const Vitamin({
    required this.id,
    required this.name,
    required this.scheduleTime,
    this.status = VitaminStatus.pending,
  });

  @override
  final String id;

  final VitaminName name;
  final VitaminScheduleTime scheduleTime;
  final VitaminStatus status;

  bool get isPending => status == VitaminStatus.pending;

  bool get isTaken => status == VitaminStatus.taken;

  bool get isSkipped => status == VitaminStatus.skipped;

  String get formattedName => name.value;

  String get formattedTime => scheduleTime.formatted;

  Vitamin markAsTaken() {
    return copyWith(status: VitaminStatus.taken);
  }

  Vitamin markAsSkipped() {
    return copyWith(status: VitaminStatus.skipped);
  }

  Vitamin copyWith({
    VitaminName? name,
    VitaminScheduleTime? scheduleTime,
    VitaminStatus? status,
  }) {
    return Vitamin(
      id: id,
      name: name ?? this.name,
      scheduleTime: scheduleTime ?? this.scheduleTime,
      status: status ?? this.status,
    );
  }
}
