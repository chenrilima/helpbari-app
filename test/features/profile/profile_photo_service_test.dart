import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/media/media.dart';
import 'package:helpbari/features/profile/application/profile_photo_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late _Storage storage;
  late ProfilePhotoService service;
  setUp(() {
    storage = _Storage();
    service = ProfilePhotoService(
      storage: storage,
      validationService: const MediaValidationService(),
      cacheService: const _Cache(),
    );
  });

  test('uploads to the mandatory private user path', () async {
    final result = await service.upload(userId: 'user-a', file: _file('new'));
    expect(result.storagePath, 'user-a/profile/new.jpg');
    expect(storage.uploaded, ['user-a/profile/new.jpg']);
    expect(result.signedUrl, contains('user-a/profile/new.jpg'));
  });

  test(
    'replace removes the previous object only after upload succeeds',
    () async {
      await service.upload(
        userId: 'user-a',
        file: _file('replacement'),
        previousPath: 'user-a/profile/old.jpg',
      );
      expect(storage.events, [
        'upload:user-a/profile/replacement.jpg',
        'remove:user-a/profile/old.jpg',
      ]);
    },
  );

  test('failed upload keeps the old object and supports retry', () async {
    storage.failUploads = 1;
    await expectLater(
      service.upload(
        userId: 'user-a',
        file: _file('retry'),
        previousPath: 'user-a/profile/old.jpg',
      ),
      throwsStateError,
    );
    expect(storage.removed, isEmpty);
    final result = await service.upload(
      userId: 'user-a',
      file: _file('retry'),
      previousPath: 'user-a/profile/old.jpg',
    );
    expect(result.storagePath, 'user-a/profile/retry.jpg');
    expect(storage.removed, ['user-a/profile/old.jpg']);
  });

  test('remove and signed URL reject another user path', () async {
    expect(
      () => service.remove(userId: 'user-b', path: 'user-a/profile/photo.jpg'),
      throwsStateError,
    );
    expect(
      () => service.createSignedUrl(
        userId: 'user-b',
        path: 'user-a/profile/photo.jpg',
      ),
      throwsStateError,
    );
    expect(storage.removed, isEmpty);
  });

  test(
    'loads a short signed URL and caches bytes for offline preview',
    () async {
      storage.downloaded = Uint8List.fromList([4, 5, 6]);
      final view = await service.load(
        userId: 'user-a',
        path: 'user-a/profile/photo.jpg',
      );
      expect(view, isNotNull);
      expect(view!.file.bytes, [4, 5, 6]);
      expect(view.file.path, startsWith('cache/'));
      expect(storage.lastSignedExpiry, 300);
      expect(view.signedUrlExpiresAt.isAfter(DateTime.now()), isTrue);
    },
  );

  test('returns null when the remote profile photo is missing', () async {
    storage.downloadError = StorageException(
      'Object not found',
      statusCode: '404',
    );

    final view = await service.load(
      userId: 'user-a',
      path: 'user-a/profile/photo.jpg',
    );

    expect(view, isNull);
  });
}

MediaFile _file(String id) => MediaFile(
  id: id,
  name: '$id.jpg',
  bytes: Uint8List.fromList([1, 2, 3]),
  type: MediaFileType.image,
  mimeType: 'image/jpeg',
  extension: 'jpg',
);

class _Cache extends MediaCacheService {
  const _Cache();
  @override
  Future<MediaFile> cache(MediaFile file) async =>
      file.copyWith(path: 'cache/${file.id}.${file.extension}');
}

class _Storage implements ProfilePhotoStorage {
  final uploaded = <String>[];
  final removed = <String>[];
  final events = <String>[];
  int failUploads = 0;
  int? lastSignedExpiry;
  Uint8List downloaded = Uint8List(0);
  Object? downloadError;

  @override
  Future<UploadedMediaFile> upload(MediaUploadRequest request) async {
    if (failUploads > 0) {
      failUploads--;
      throw StateError('offline');
    }
    uploaded.add(request.path);
    events.add('upload:${request.path}');
    return UploadedMediaFile(
      path: request.path,
      bucketId: request.bucketId!,
      name: request.file.name,
      type: request.file.type,
      mimeType: request.file.mimeType,
      sizeInBytes: request.file.sizeInBytes,
      signedUrl: 'signed://${request.path}',
    );
  }

  @override
  Future<Uint8List> download({required String path, String? bucketId}) async {
    if (downloadError != null) throw downloadError!;
    return downloaded;
  }

  @override
  Future<void> remove({required List<String> paths, String? bucketId}) async {
    removed.addAll(paths);
    events.addAll(paths.map((path) => 'remove:$path'));
  }

  @override
  Future<String> createSignedUrl({
    required String path,
    required int expiresIn,
    String? bucketId,
  }) async {
    lastSignedExpiry = expiresIn;
    return 'signed://$path';
  }
}
