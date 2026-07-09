import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import '../../services/uuid_service.dart';
import '../models/media_file.dart';
import '../models/media_file_type.dart';
import '../models/media_processing_config.dart';
import '../models/media_source.dart';
import 'image_processing_service.dart';
import 'media_cache_service.dart';

class MediaPickerService {
  const MediaPickerService({
    required UuidService uuidService,
    required ImagePicker imagePicker,
    required ImageProcessingService imageProcessingService,
    required MediaCacheService cacheService,
  }) : _uuidService = uuidService,
       _imagePicker = imagePicker,
       _imageProcessingService = imageProcessingService,
       _cacheService = cacheService;

  final UuidService _uuidService;
  final ImagePicker _imagePicker;
  final ImageProcessingService _imageProcessingService;
  final MediaCacheService _cacheService;

  Future<MediaFile?> pickImage({
    MediaSource source = MediaSource.gallery,
    MediaProcessingConfig processingConfig = const MediaProcessingConfig(),
  }) async {
    final imageSource = switch (source) {
      MediaSource.camera => ImageSource.camera,
      MediaSource.gallery || MediaSource.files => ImageSource.gallery,
    };

    final picked = await _imagePicker.pickImage(source: imageSource);
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    final mimeType =
        lookupMimeType(picked.path, headerBytes: bytes) ?? 'image/jpeg';
    final extension = _extensionFromPathOrMime(picked.path, mimeType);

    var mediaFile = MediaFile(
      id: _uuidService.generate(),
      name: picked.name,
      bytes: bytes,
      type: MediaFileType.image,
      mimeType: mimeType,
      extension: extension,
      path: picked.path,
      source: source,
    );

    mediaFile = await _imageProcessingService.processImage(
      mediaFile,
      config: processingConfig,
    );

    if (processingConfig.cacheFiles) {
      mediaFile = await _cacheService.cache(mediaFile);
    }

    return mediaFile;
  }

  Future<MediaFile?> pickPdf({
    MediaProcessingConfig processingConfig = const MediaProcessingConfig(),
  }) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );

    final file = result?.files.single;
    if (file == null) return null;

    final bytes = file.bytes;
    if (bytes == null) return null;

    var mediaFile = MediaFile(
      id: _uuidService.generate(),
      name: file.name,
      bytes: bytes,
      type: MediaFileType.pdf,
      mimeType: 'application/pdf',
      extension: 'pdf',
      path: file.path,
      source: MediaSource.files,
    );

    if (processingConfig.cacheFiles) {
      mediaFile = await _cacheService.cache(mediaFile);
    }

    return mediaFile;
  }

  String _extensionFromPathOrMime(String path, String mimeType) {
    final extension = p.extension(path).replaceFirst('.', '').toLowerCase();
    if (extension.isNotEmpty) return extension;

    return switch (mimeType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };
  }
}
