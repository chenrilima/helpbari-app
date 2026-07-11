import 'dart:typed_data';

import '../../../core/media/media.dart';

class ProfilePhotoService {
  const ProfilePhotoService({
    required ProfilePhotoStorage storage,
    required MediaValidationService validationService,
    required MediaCacheService cacheService,
  }) : _storage = storage,
       _validationService = validationService,
       _cacheService = cacheService;

  static const bucket = 'profile-photos';
  static const signedUrlLifetime = Duration(minutes: 5);
  static const validationConfig = MediaValidationConfig(
    allowedTypes: {MediaFileType.image},
    maxImageSizeInBytes: 5 * 1024 * 1024,
  );

  final ProfilePhotoStorage _storage;
  final MediaValidationService _validationService;
  final MediaCacheService _cacheService;

  Future<ProfilePhotoUpload> upload({
    required String userId,
    required MediaFile file,
    String? previousPath,
  }) async {
    final error = _validationService.validateFile(
      file,
      config: validationConfig,
    );
    if (error != null) throw error;
    if (!const {
      'image/jpeg',
      'image/png',
      'image/webp',
    }.contains(file.mimeType)) {
      throw StateError('Formato de imagem não permitido.');
    }
    _assertOwnedPath(previousPath, userId, allowNull: true);
    final path = '$userId/profile/${file.id}.${file.extension.toLowerCase()}';
    final cached = await _cacheService.cache(file);
    final uploaded = await _storage.upload(
      MediaUploadRequest(
        file: file,
        path: path,
        bucketId: bucket,
        signedUrlExpiresIn: signedUrlLifetime.inSeconds,
      ),
    );
    if (previousPath != null && previousPath != path) {
      try {
        await _storage.remove(paths: [previousPath], bucketId: bucket);
      } catch (_) {
        // The new object and Profile path remain valid; cleanup can be retried.
      }
    }
    return ProfilePhotoUpload(
      storagePath: path,
      signedUrl: uploaded.signedUrl,
      signedUrlExpiresAt: DateTime.now().add(signedUrlLifetime),
      cachedFile: cached,
    );
  }

  Future<ProfilePhotoView> load({
    required String userId,
    required String path,
  }) async {
    _assertOwnedPath(path, userId);
    final bytes = await _storage.download(path: path, bucketId: bucket);
    final extension = path.split('.').last.toLowerCase();
    final file = await _cacheService.cache(
      MediaFile(
        id: _cacheId(path),
        name: path.split('/').last,
        bytes: bytes,
        type: MediaFileType.image,
        mimeType: _mime(extension),
        extension: extension,
      ),
    );
    final signedUrl = await createSignedUrl(userId: userId, path: path);
    return ProfilePhotoView(
      file: file,
      signedUrl: signedUrl,
      signedUrlExpiresAt: DateTime.now().add(signedUrlLifetime),
    );
  }

  Future<String> createSignedUrl({
    required String userId,
    required String path,
  }) {
    _assertOwnedPath(path, userId);
    return _storage.createSignedUrl(
      path: path,
      bucketId: bucket,
      expiresIn: signedUrlLifetime.inSeconds,
    );
  }

  Future<void> remove({required String userId, required String path}) {
    _assertOwnedPath(path, userId);
    return _storage.remove(paths: [path], bucketId: bucket);
  }

  void _assertOwnedPath(String? path, String userId, {bool allowNull = false}) {
    if (path == null && allowNull) return;
    if (path == null || !path.startsWith('$userId/profile/')) {
      throw StateError('Caminho de foto não pertence ao usuário autenticado.');
    }
  }

  String _cacheId(String path) => path.codeUnits
      .fold<int>(17, (value, unit) => 37 * value + unit)
      .abs()
      .toString();
  String _mime(String extension) => switch (extension) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };
}

abstract interface class ProfilePhotoStorage {
  Future<UploadedMediaFile> upload(MediaUploadRequest request);
  Future<Uint8List> download({required String path, String? bucketId});
  Future<void> remove({required List<String> paths, String? bucketId});
  Future<String> createSignedUrl({
    required String path,
    required int expiresIn,
    String? bucketId,
  });
}

class MediaUploadProfilePhotoStorage implements ProfilePhotoStorage {
  const MediaUploadProfilePhotoStorage(this.service);
  final MediaUploadService service;
  @override
  Future<UploadedMediaFile> upload(MediaUploadRequest request) =>
      service.upload(request);
  @override
  Future<Uint8List> download({required String path, String? bucketId}) =>
      service.download(path: path, bucketId: bucketId);
  @override
  Future<void> remove({required List<String> paths, String? bucketId}) =>
      service.remove(paths: paths, bucketId: bucketId);
  @override
  Future<String> createSignedUrl({
    required String path,
    required int expiresIn,
    String? bucketId,
  }) => service.createSignedUrl(
    path: path,
    expiresIn: expiresIn,
    bucketId: bucketId,
  );
}

class ProfilePhotoUpload {
  const ProfilePhotoUpload({
    required this.storagePath,
    required this.signedUrl,
    required this.signedUrlExpiresAt,
    required this.cachedFile,
  });
  final String storagePath;
  final String? signedUrl;
  final DateTime signedUrlExpiresAt;
  final MediaFile cachedFile;
}

class ProfilePhotoView {
  const ProfilePhotoView({
    required this.file,
    required this.signedUrl,
    required this.signedUrlExpiresAt,
  });
  final MediaFile file;
  final String signedUrl;
  final DateTime signedUrlExpiresAt;
}
