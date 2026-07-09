import 'media_file_type.dart';

class MediaValidationConfig {
  const MediaValidationConfig({
    this.allowedTypes = const {MediaFileType.image, MediaFileType.pdf},
    this.maxImageSizeInBytes = 8 * 1024 * 1024,
    this.maxPdfSizeInBytes = 12 * 1024 * 1024,
    this.maxFiles = 1,
    this.required = false,
  });

  final Set<MediaFileType> allowedTypes;
  final int maxImageSizeInBytes;
  final int maxPdfSizeInBytes;
  final int maxFiles;
  final bool required;

  int maxSizeFor(MediaFileType type) {
    return switch (type) {
      MediaFileType.image => maxImageSizeInBytes,
      MediaFileType.pdf => maxPdfSizeInBytes,
    };
  }
}
