import 'dart:typed_data';

import 'report_template.dart';

class GeneratedMedicalReport {
  const GeneratedMedicalReport({
    required this.bytes,
    required this.fileName,
    required this.generatedAt,
    required this.template,
    required this.hasClinicalData,
    required this.reportVersion,
    this.savedPath,
  });

  final Uint8List bytes;
  final String fileName;
  final DateTime generatedAt;
  final ReportTemplate template;
  final bool hasClinicalData;
  final String reportVersion;
  final String? savedPath;

  GeneratedMedicalReport copyWith({String? savedPath}) {
    return GeneratedMedicalReport(
      bytes: bytes,
      fileName: fileName,
      generatedAt: generatedAt,
      template: template,
      hasClinicalData: hasClinicalData,
      reportVersion: reportVersion,
      savedPath: savedPath ?? this.savedPath,
    );
  }
}
