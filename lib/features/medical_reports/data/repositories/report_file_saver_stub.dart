import 'dart:typed_data';

Future<String> saveReportFile({
  required Uint8List bytes,
  required String fileName,
}) async {
  throw UnsupportedError('Plataforma sem suporte para download de relatório.');
}
