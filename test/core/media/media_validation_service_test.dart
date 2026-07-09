import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/media/media.dart';

void main() {
  group('MediaValidationService', () {
    const service = MediaValidationService();

    test('accepts an allowed image inside size limit', () {
      final file = _mediaFile(
        type: MediaFileType.image,
        mimeType: 'image/jpeg',
        extension: 'jpg',
        size: 1024,
      );

      final result = service.validateFile(file);

      expect(result, isNull);
    });

    test('rejects a type outside allowed types', () {
      final file = _mediaFile(
        type: MediaFileType.pdf,
        mimeType: 'application/pdf',
        extension: 'pdf',
        size: 1024,
      );

      final result = service.validateFile(
        file,
        config: const MediaValidationConfig(
          allowedTypes: {MediaFileType.image},
        ),
      );

      expect(result?.code, 'media_type_not_allowed');
    });

    test('rejects files above the configured size limit', () {
      final file = _mediaFile(
        type: MediaFileType.image,
        mimeType: 'image/jpeg',
        extension: 'jpg',
        size: 3,
      );

      final result = service.validateFile(
        file,
        config: const MediaValidationConfig(maxImageSizeInBytes: 2),
      );

      expect(result?.code, 'media_file_too_large');
    });

    test('rejects more files than allowed', () {
      final files = [
        _mediaFile(id: '1', size: 1),
        _mediaFile(id: '2', size: 1),
      ];

      final result = service.validateFiles(
        files,
        config: const MediaValidationConfig(maxFiles: 1),
      );

      expect(result?.code, 'media_too_many_files');
    });

    test('rejects empty required selections', () {
      final result = service.validateFiles(
        const [],
        config: const MediaValidationConfig(required: true),
      );

      expect(result?.code, 'media_required');
    });
  });
}

MediaFile _mediaFile({
  String id = 'media-id',
  MediaFileType type = MediaFileType.image,
  String mimeType = 'image/jpeg',
  String extension = 'jpg',
  int size = 1,
}) {
  return MediaFile(
    id: id,
    name: 'file.$extension',
    bytes: Uint8List(size),
    type: type,
    mimeType: mimeType,
    extension: extension,
  );
}
