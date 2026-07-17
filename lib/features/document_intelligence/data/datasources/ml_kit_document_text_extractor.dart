import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../domain/repositories/document_intelligence_contracts.dart';

class MlKitDocumentTextExtractor implements DocumentTextExtractor {
  MlKitDocumentTextExtractor({TextRecognizer? recognizer})
    : _recognizer =
          recognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  @override
  String get engine => 'mlkit_on_device';

  @override
  bool supportsMimeType(String mimeType) => mimeType.startsWith('image/');

  @override
  Future<String> extract({
    required String path,
    required String mimeType,
  }) async {
    if (!supportsMimeType(mimeType)) {
      throw const DocumentExtractionException(
        code: 'pdf_text_extraction_unavailable',
        message: 'A leitura de PDF ainda não está disponível neste aparelho.',
      );
    }
    try {
      final result = await _recognizer.processImage(
        InputImage.fromFilePath(path),
      );
      final text = result.text.trim();
      if (text.isEmpty) {
        throw const DocumentExtractionException(
          code: 'text_not_found',
          message: 'Não foi possível encontrar texto no documento.',
        );
      }
      return text;
    } on DocumentExtractionException {
      rethrow;
    } catch (_) {
      throw const DocumentExtractionException(
        code: 'ocr_unavailable',
        message: 'Não foi possível analisar o documento. Tente novamente.',
      );
    }
  }

  Future<void> close() => _recognizer.close();
}

class DocumentExtractionException implements Exception {
  const DocumentExtractionException({
    required this.code,
    required this.message,
  });
  final String code;
  final String message;
}
