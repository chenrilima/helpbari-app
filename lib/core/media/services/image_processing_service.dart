import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as p;

import '../models/media_file.dart';
import '../models/media_processing_config.dart';

class ImageProcessingService {
  const ImageProcessingService();

  Future<MediaFile> processImage(
    MediaFile file, {
    MediaProcessingConfig config = const MediaProcessingConfig(),
  }) async {
    var processed = file;

    if (config.cropImages && processed.path != null) {
      final cropped = await ImageCropper().cropImage(
        sourcePath: processed.path!,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Ajustar imagem',
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Ajustar imagem'),
        ],
      );

      if (cropped != null) {
        final bytes = await cropped.readAsBytes();
        processed = processed.copyWith(
          bytes: bytes,
          path: cropped.path,
          extension: p.extension(cropped.path).replaceFirst('.', ''),
        );
      }
    }

    if (!config.compressImages) return processed;

    final compressed = await FlutterImageCompress.compressWithList(
      processed.bytes,
      minWidth: config.minImageWidth,
      minHeight: config.minImageHeight,
      quality: config.imageQuality,
      format: CompressFormat.jpeg,
    );

    return processed.copyWith(
      bytes: compressed,
      mimeType: 'image/jpeg',
      extension: 'jpg',
      name: _withExtension(processed.name, 'jpg'),
    );
  }

  String _withExtension(String name, String extension) {
    final basename = p.basenameWithoutExtension(name);
    return '$basename.$extension';
  }
}
