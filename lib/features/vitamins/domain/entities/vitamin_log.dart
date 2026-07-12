import '../../../../core/domain/entity.dart';
import '../value_objects/vitamin_status.dart';

class VitaminLog extends Entity {
  const VitaminLog({
    required this.id,
    required this.vitaminId,
    required this.date,
    required this.status,
  });
  @override
  final String id;
  final String vitaminId;
  final DateTime date;
  final VitaminStatus status;

  VitaminLog copyWith({VitaminStatus? status}) => VitaminLog(
    id: id,
    vitaminId: vitaminId,
    date: date,
    status: status ?? this.status,
  );
}
