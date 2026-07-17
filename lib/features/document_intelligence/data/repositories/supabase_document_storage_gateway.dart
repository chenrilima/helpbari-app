import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/storage/supabase_storage_service.dart';
import '../../domain/repositories/document_intelligence_contracts.dart';

class SupabaseDocumentStorageGateway implements DocumentStorageGateway {
  const SupabaseDocumentStorageGateway(this._storage);
  static const bucket = 'clinical-documents';
  final SupabaseStorageService _storage;

  @override
  Future<String> upload({
    required String userId,
    required String documentId,
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    if (!_safeSegment.hasMatch(userId) || !_safeSegment.hasMatch(documentId)) {
      throw const FormatException('invalid_document_path');
    }
    final extension = p.extension(fileName).toLowerCase();
    final allowedExtension = switch (mimeType) {
      'application/pdf' => '.pdf',
      'image/png' => '.png',
      'image/webp' => '.webp',
      _ when mimeType.startsWith('image/') => '.jpg',
      _ => throw const FormatException('invalid_document_mime'),
    };
    final path =
        '$userId/$documentId/original${extension == allowedExtension ? extension : allowedExtension}';
    await _storage.uploadBinary(
      path: path,
      bytes: bytes,
      bucketId: bucket,
      fileOptions: FileOptions(contentType: mimeType, upsert: false),
    );
    return path;
  }

  static final _safeSegment = RegExp(r'^[A-Za-z0-9_-]+$');

  @override
  Future<Uint8List> download(String remotePath) {
    _validateRemotePath(remotePath);
    return _storage.downloadBinary(path: remotePath, bucketId: bucket);
  }

  @override
  Future<void> remove(String remotePath) {
    _validateRemotePath(remotePath);
    return _storage.remove(paths: [remotePath], bucketId: bucket);
  }

  void _validateRemotePath(String path) {
    if (path.startsWith('/') ||
        path.contains('..') ||
        path.split('/').length != 3) {
      throw const FormatException('invalid_document_path');
    }
  }
}
