import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

Future<String> saveReportFile({
  required Uint8List bytes,
  required String fileName,
}) async {
  final directory = await getApplicationDocumentsDirectory();
  final reportsDirectory = Directory(path.join(directory.path, 'reports'));

  if (!reportsDirectory.existsSync()) {
    await reportsDirectory.create(recursive: true);
  }

  final file = File(path.join(reportsDirectory.path, fileName));

  await file.writeAsBytes(bytes, flush: true);

  return file.path;
}
