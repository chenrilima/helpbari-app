import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String?> writeMediaCache(String fileName, List<int> bytes) async {
  final directory = await getTemporaryDirectory();
  final mediaDirectory = Directory(p.join(directory.path, 'helpbari_media'));

  if (!mediaDirectory.existsSync()) {
    await mediaDirectory.create(recursive: true);
  }

  final cachePath = p.join(mediaDirectory.path, fileName);
  final cachedFile = File(cachePath);
  await cachedFile.writeAsBytes(bytes, flush: true);

  return cachePath;
}

Future<void> removeMediaCache(String path) async {
  final cachedFile = File(path);
  if (cachedFile.existsSync()) {
    await cachedFile.delete();
  }
}

Future<void> clearMediaCache() async {
  final directory = await getTemporaryDirectory();
  final mediaDirectory = Directory(p.join(directory.path, 'helpbari_media'));

  if (mediaDirectory.existsSync()) {
    await mediaDirectory.delete(recursive: true);
  }
}
