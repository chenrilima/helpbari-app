import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/media/media.dart';
import 'package:helpbari/features/exams/application/exam_attachment_service.dart';

void main() {
  late _Storage storage;
  late ExamAttachmentService service;
  setUp(() {
    storage = _Storage();
    service = ExamAttachmentService(
      storage: storage,
      validation: const MediaValidationService(),
      cache: const _Cache(),
    );
  });
  test('uploads image and PDF to owned private paths', () async {
    final image = await service.upload(
      userId: 'user-a',
      examId: 'exam-1',
      file: _file('image', MediaFileType.image, 'jpg', 'image/jpeg'),
    );
    final pdf = await service.upload(
      userId: 'user-a',
      examId: 'exam-2',
      file: _file('pdf', MediaFileType.pdf, 'pdf', 'application/pdf'),
    );
    expect(image.path, 'user-a/exam-1/image.jpg');
    expect(pdf.path, 'user-a/exam-2/pdf.pdf');
    expect(storage.uploaded, hasLength(2));
  });
  test('failed upload keeps no removal and supports retry', () async {
    storage.failUpload = true;
    await expectLater(
      service.upload(
        userId: 'user-a',
        examId: 'exam',
        file: _file('new', MediaFileType.image, 'png', 'image/png'),
      ),
      throwsStateError,
    );
    expect(storage.removed, isEmpty);
    storage.failUpload = false;
    expect(
      (await service.upload(
        userId: 'user-a',
        examId: 'exam',
        file: _file('new', MediaFileType.image, 'png', 'image/png'),
      )).path,
      'user-a/exam/new.png',
    );
  });
  test('loads cached preview and short signed URL', () async {
    final view = await service.load(
      userId: 'user-a',
      examId: 'exam',
      path: 'user-a/exam/file.pdf',
    );
    expect(view.file.path, startsWith('cache/'));
    expect(view.file.type, MediaFileType.pdf);
    expect(view.signedUrl, contains('user-a/exam/file.pdf'));
  });
  test('rejects another user path for view and removal', () async {
    expect(
      () => service.createSignedUrl(
        userId: 'user-b',
        examId: 'exam',
        path: 'user-a/exam/file.pdf',
      ),
      throwsStateError,
    );
    expect(
      () => service.remove(
        userId: 'user-b',
        examId: 'exam',
        path: 'user-a/exam/file.pdf',
      ),
      throwsStateError,
    );
    expect(storage.removed, isEmpty);
  });
}

MediaFile _file(String id, MediaFileType type, String extension, String mime) =>
    MediaFile(
      id: id,
      name: '$id.$extension',
      bytes: Uint8List.fromList([1, 2, 3]),
      type: type,
      mimeType: mime,
      extension: extension,
    );

class _Cache extends MediaCacheService {
  const _Cache();
  @override
  Future<MediaFile> cache(MediaFile file) async =>
      file.copyWith(path: 'cache/${file.name}');
}

class _Storage implements ExamAttachmentStorage {
  final uploaded = <String>[];
  final removed = <String>[];
  bool failUpload = false;
  @override
  Future<UploadedMediaFile> upload(MediaUploadRequest r) async {
    if (failUpload) throw StateError('offline');
    uploaded.add(r.path);
    return UploadedMediaFile(
      path: r.path,
      bucketId: r.bucketId ?? '',
      name: r.file.name,
      type: r.file.type,
      mimeType: r.file.mimeType,
      sizeInBytes: r.file.sizeInBytes,
      signedUrl: 'signed:${r.path}',
    );
  }

  @override
  Future<Uint8List> download({required String path, String? bucketId}) async =>
      Uint8List.fromList([1, 2]);
  @override
  Future<void> remove({required List<String> paths, String? bucketId}) async =>
      removed.addAll(paths);
  @override
  Future<String> createSignedUrl({
    required String path,
    required int expiresIn,
    String? bucketId,
  }) async => 'signed:$path';
}
