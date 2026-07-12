import '../entities/vitamin_log.dart';
import '../value_objects/vitamin_status.dart';

abstract interface class VitaminLogRepository {
  Future<List<VitaminLog>> getByPeriod(DateTime start, DateTime end);
  Future<VitaminLog> setStatus({
    required String vitaminId,
    required DateTime date,
    required VitaminStatus status,
  });
  Future<void> deleteForVitamin(String vitaminId);
}
