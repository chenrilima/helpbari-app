import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

import '../../config/environment.dart';
import '../../supabase/storage/supabase_storage_service.dart';
import '../models/media_upload_request.dart';
import '../models/uploaded_media_file.dart';

class MediaUploadService {
  const MediaUploadService({required SupabaseStorageService storageService})
    : _storageService = storageService;

  final SupabaseStorageService _storageService;

  Future<UploadedMediaFile> upload(MediaUploadRequest request) async {
    final fileOptions =
        request.fileOptions ??
        FileOptions(contentType: request.file.mimeType, upsert: false);
    final bucketId = request.bucketId ?? Environment.supabaseStorageBucket;

    await _storageService.uploadBinary(
      path: request.path,
      bytes: request.file.bytes,
      bucketId: bucketId,
      fileOptions: fileOptions,
    );

    final publicUrl = request.createPublicUrl
        ? _storageService.getPublicUrl(path: request.path, bucketId: bucketId)
        : null;
    final signedUrl = request.signedUrlExpiresIn == null
        ? null
        : await _storageService.createSignedUrl(
            path: request.path,
            bucketId: bucketId,
            expiresIn: request.signedUrlExpiresIn!,
          );

    return UploadedMediaFile(
      path: request.path,
      bucketId: bucketId,
      name: request.file.name,
      type: request.file.type,
      mimeType: request.file.mimeType,
      sizeInBytes: request.file.sizeInBytes,
      publicUrl: publicUrl,
      signedUrl: signedUrl,
    );
  }

  Future<Uint8List> download({required String path, String? bucketId}) {
    return _storageService.downloadBinary(path: path, bucketId: bucketId);
  }

  Future<void> remove({required List<String> paths, String? bucketId}) {
    return _storageService.remove(paths: paths, bucketId: bucketId);
  }
}
