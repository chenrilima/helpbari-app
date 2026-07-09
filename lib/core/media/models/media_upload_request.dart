import 'package:supabase_flutter/supabase_flutter.dart';

import 'media_file.dart';

class MediaUploadRequest {
  const MediaUploadRequest({
    required this.file,
    required this.path,
    this.bucketId,
    this.fileOptions,
    this.createPublicUrl = false,
    this.signedUrlExpiresIn,
  });

  final MediaFile file;
  final String path;
  final String? bucketId;
  final FileOptions? fileOptions;
  final bool createPublicUrl;
  final int? signedUrlExpiresIn;
}
