import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

Future<void> removeKnownPrivacyFiles(Iterable<String> paths) async {
  final candidates = paths.toSet();
  if (candidates.isEmpty) return;

  final temporaryDirectory = await getTemporaryDirectory();
  final mediaRoot = path.normalize(
    path.join(temporaryDirectory.path, 'helpbari_media'),
  );

  for (final candidate in candidates) {
    final normalized = path.normalize(candidate);
    if (!path.isWithin(mediaRoot, normalized)) continue;
    final file = File(normalized);
    if (await file.exists()) await file.delete();
  }
}
