import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/environment.dart';
import '../interceptors/supabase_request_interceptor.dart';

class SupabaseStorageService {
  const SupabaseStorageService({
    required SupabaseClient client,
    required SupabaseInterceptorRunner interceptorRunner,
    this.defaultBucket = Environment.supabaseStorageBucket,
  }) : _client = client,
       _interceptorRunner = interceptorRunner;

  final SupabaseClient _client;
  final SupabaseInterceptorRunner _interceptorRunner;
  final String defaultBucket;

  StorageFileApi bucket([String? bucketId]) {
    return _client.storage.from(bucketId ?? defaultBucket);
  }

  Future<String> uploadBinary({
    required String path,
    required Uint8List bytes,
    String? bucketId,
    FileOptions fileOptions = const FileOptions(upsert: false),
  }) {
    final bucketName = bucketId ?? defaultBucket;

    return _interceptorRunner.run(
      context: SupabaseRequestContext(
        operation: 'storage.uploadBinary',
        bucket: bucketName,
        metadata: {'requiresAuth': true},
      ),
      request: () => _client.storage
          .from(bucketName)
          .uploadBinary(path, bytes, fileOptions: fileOptions),
    );
  }

  Future<void> remove({required List<String> paths, String? bucketId}) async {
    final bucketName = bucketId ?? defaultBucket;

    await _interceptorRunner.run(
      context: SupabaseRequestContext(
        operation: 'storage.remove',
        bucket: bucketName,
        metadata: {'requiresAuth': true},
      ),
      request: () => _client.storage.from(bucketName).remove(paths),
    );
  }

  String getPublicUrl({required String path, String? bucketId}) {
    return _client.storage.from(bucketId ?? defaultBucket).getPublicUrl(path);
  }

  Future<String> createSignedUrl({
    required String path,
    required int expiresIn,
    String? bucketId,
  }) {
    final bucketName = bucketId ?? defaultBucket;

    return _interceptorRunner.run(
      context: SupabaseRequestContext(
        operation: 'storage.createSignedUrl',
        bucket: bucketName,
        metadata: {'requiresAuth': true},
      ),
      request: () =>
          _client.storage.from(bucketName).createSignedUrl(path, expiresIn),
    );
  }
}
