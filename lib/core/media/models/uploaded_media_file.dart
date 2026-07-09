import 'media_file_type.dart';

class UploadedMediaFile {
  const UploadedMediaFile({
    required this.path,
    required this.bucketId,
    required this.name,
    required this.type,
    required this.mimeType,
    required this.sizeInBytes,
    this.publicUrl,
    this.signedUrl,
  });

  final String path;
  final String bucketId;
  final String name;
  final MediaFileType type;
  final String mimeType;
  final int sizeInBytes;
  final String? publicUrl;
  final String? signedUrl;
}
