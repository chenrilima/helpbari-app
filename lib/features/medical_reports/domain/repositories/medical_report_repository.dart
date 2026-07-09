import '../entities/entities.dart';
import '../models/models.dart';

abstract interface class MedicalReportRepository {
  Future<GeneratedMedicalReport> generate({
    required MedicalReportSnapshot snapshot,
    required ReportTemplate template,
  });
}
