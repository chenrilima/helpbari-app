enum ReportAttachmentType { image, pdf }

class ReportAttachment {
  const ReportAttachment({
    required this.id,
    required this.name,
    required this.type,
    required this.path,
    this.mimeType,
  });

  final String id;
  final String name;
  final ReportAttachmentType type;
  final String path;
  final String? mimeType;
}
