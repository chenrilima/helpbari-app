import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

Future<String?> saveDocumentFile({
  required Uint8List bytes,
  required String fileName,
}) async {
  final directory = await getApplicationDocumentsDirectory();
  final documentsDirectory = Directory(
    path.join(directory.path, 'document_center'),
  );

  if (!documentsDirectory.existsSync()) {
    await documentsDirectory.create(recursive: true);
  }

  final file = File(path.join(documentsDirectory.path, fileName));
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
