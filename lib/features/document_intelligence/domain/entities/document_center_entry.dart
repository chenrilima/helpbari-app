import 'document_models.dart';

class DocumentCenterEntry {
  const DocumentCenterEntry({
    required this.document,
    this.processing,
    this.linkedPrescriptionId,
  });
  final DocumentInput document;
  final DocumentProcessing? processing;
  final String? linkedPrescriptionId;
  bool get isOrphan => linkedPrescriptionId == null;
}
