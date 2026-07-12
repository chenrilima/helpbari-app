import 'dart:typed_data';

class PrivacyExportPackage {
  const PrivacyExportPackage({
    required this.fileName,
    required this.bytes,
    required this.generatedAt,
    required this.categoryCounts,
  });

  final String fileName;
  final Uint8List bytes;
  final DateTime generatedAt;
  final Map<String, int> categoryCounts;
}
