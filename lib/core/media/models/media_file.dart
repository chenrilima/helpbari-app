import 'dart:typed_data';

import 'media_file_type.dart';
import 'media_source.dart';

class MediaFile {
  const MediaFile({
    required this.id,
    required this.name,
    required this.bytes,
    required this.type,
    required this.mimeType,
    required this.extension,
    this.path,
    this.source,
  });

  final String id;
  final String name;
  final Uint8List bytes;
  final MediaFileType type;
  final String mimeType;
  final String extension;
  final String? path;
  final MediaSource? source;

  int get sizeInBytes => bytes.lengthInBytes;

  MediaFile copyWith({
    String? id,
    String? name,
    Uint8List? bytes,
    MediaFileType? type,
    String? mimeType,
    String? extension,
    String? path,
    MediaSource? source,
  }) {
    return MediaFile(
      id: id ?? this.id,
      name: name ?? this.name,
      bytes: bytes ?? this.bytes,
      type: type ?? this.type,
      mimeType: mimeType ?? this.mimeType,
      extension: extension ?? this.extension,
      path: path ?? this.path,
      source: source ?? this.source,
    );
  }
}
