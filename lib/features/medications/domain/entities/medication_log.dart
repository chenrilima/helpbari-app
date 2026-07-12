import '../../../../core/domain/entity.dart';
import '../value_objects/medication_status.dart';

class MedicationLog extends Entity {
  const MedicationLog({
    required this.id,
    required this.medicationId,
    required this.date,
    required this.status,
  });
  @override
  final String id;
  final String medicationId;
  final DateTime date;
  final MedicationStatus status;
}
