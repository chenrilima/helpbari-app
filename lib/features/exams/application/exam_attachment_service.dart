import 'dart:typed_data';
import '../../../core/media/media.dart';

class ExamAttachmentService {
  const ExamAttachmentService({
    required ExamAttachmentStorage storage,
    required MediaValidationService validation,
    required MediaCacheService cache,
  }) : _storage = storage,
       _validation = validation,
       _cache = cache;
  static const bucket = 'exam-attachments';
  static const signedUrlLifetime = Duration(minutes: 5);
  static const validationConfig = MediaValidationConfig(
    allowedTypes: {MediaFileType.image, MediaFileType.pdf},
    maxImageSizeInBytes: 8 * 1024 * 1024,
    maxPdfSizeInBytes: 12 * 1024 * 1024,
    maxFiles: 1,
  );
  final ExamAttachmentStorage _storage;
  final MediaValidationService _validation;
  final MediaCacheService _cache;
  Future<ExamAttachmentUpload> upload({
    required String userId,
    required String examId,
    required MediaFile file,
  }) async {
    final error = _validation.validateFile(file, config: validationConfig);
    if (error != null) throw error;
    if (!const {
      'image/jpeg',
      'image/png',
      'image/webp',
      'application/pdf',
    }.contains(file.mimeType)) {
      throw StateError('Formato de anexo não permitido.');
    }
    final safeName = '${file.id}.${file.extension.toLowerCase()}';
    final path = '$userId/$examId/$safeName';
    final cached = await _cache.cache(file);
    final uploaded = await _storage.upload(
      MediaUploadRequest(
        file: file,
        path: path,
        bucketId: bucket,
        signedUrlExpiresIn: signedUrlLifetime.inSeconds,
      ),
    );
    return ExamAttachmentUpload(
      path: path,
      cachedFile: cached,
      signedUrl: uploaded.signedUrl,
      signedUrlExpiresAt: DateTime.now().add(signedUrlLifetime),
    );
  }

  Future<ExamAttachmentView> load({
    required String userId,
    required String examId,
    required String path,
  }) async {
    _assertOwned(path, userId, examId);
    final bytes = await _storage.download(path: path, bucketId: bucket);
    final extension = path.split('.').last.toLowerCase();
    final type = extension == 'pdf' ? MediaFileType.pdf : MediaFileType.image;
    final file = await _cache.cache(
      MediaFile(
        id: _cacheId(path),
        name: path.split('/').last,
        bytes: bytes,
        type: type,
        mimeType: extension == 'pdf'
            ? 'application/pdf'
            : _imageMime(extension),
        extension: extension,
      ),
    );
    final url = await createSignedUrl(
      userId: userId,
      examId: examId,
      path: path,
    );
    return ExamAttachmentView(
      file: file,
      signedUrl: url,
      signedUrlExpiresAt: DateTime.now().add(signedUrlLifetime),
    );
  }

  Future<String> createSignedUrl({
    required String userId,
    required String examId,
    required String path,
  }) {
    _assertOwned(path, userId, examId);
    return _storage.createSignedUrl(
      path: path,
      bucketId: bucket,
      expiresIn: signedUrlLifetime.inSeconds,
    );
  }

  Future<void> remove({
    required String userId,
    required String examId,
    required String path,
  }) {
    _assertOwned(path, userId, examId);
    return _storage.remove(paths: [path], bucketId: bucket);
  }

  void _assertOwned(String path, String userId, String examId) {
    if (!path.startsWith('$userId/$examId/')) {
      throw StateError('Caminho de anexo não pertence ao usuário autenticado.');
    }
  }

  String _cacheId(String path) =>
      path.codeUnits.fold<int>(17, (v, u) => 37 * v + u).abs().toString();
  String _imageMime(String e) => e == 'png'
      ? 'image/png'
      : e == 'webp'
      ? 'image/webp'
      : 'image/jpeg';
}

abstract interface class ExamAttachmentStorage {
  Future<UploadedMediaFile> upload(MediaUploadRequest request);
  Future<Uint8List> download({required String path, String? bucketId});
  Future<void> remove({required List<String> paths, String? bucketId});
  Future<String> createSignedUrl({
    required String path,
    required int expiresIn,
    String? bucketId,
  });
}

class MediaUploadExamAttachmentStorage implements ExamAttachmentStorage {
  const MediaUploadExamAttachmentStorage(this.service);
  final MediaUploadService service;
  @override
  Future<UploadedMediaFile> upload(MediaUploadRequest r) => service.upload(r);
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

class ExamAttachmentUpload {
  const ExamAttachmentUpload({
    required this.path,
    required this.cachedFile,
    required this.signedUrl,
    required this.signedUrlExpiresAt,
  });
  final String path;
  final MediaFile cachedFile;
  final String? signedUrl;
  final DateTime signedUrlExpiresAt;
}

class ExamAttachmentView {
  const ExamAttachmentView({
    required this.file,
    required this.signedUrl,
    required this.signedUrlExpiresAt,
  });
  final MediaFile file;
  final String signedUrl;
  final DateTime signedUrlExpiresAt;
}
