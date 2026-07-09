import 'dart:typed_data';

import 'report_template.dart';

class GeneratedMedicalReport {
  const GeneratedMedicalReport({
    required this.bytes,
    required this.fileName,
    required this.generatedAt,
    required this.template,
    this.savedPath,
  });

  final Uint8List bytes;
  final String fileName;
  final DateTime generatedAt;
  final ReportTemplate template;
  final String? savedPath;

  GeneratedMedicalReport copyWith({String? savedPath}) {
    return GeneratedMedicalReport(
      bytes: bytes,
      fileName: fileName,
      generatedAt: generatedAt,
      template: template,
      savedPath: savedPath ?? this.savedPath,
    );
  }
}
