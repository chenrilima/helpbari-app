import '../models/media_file.dart';
import 'media_cache_store_stub.dart'
    if (dart.library.io) 'media_cache_store_io.dart';

class MediaCacheService {
  const MediaCacheService();

  Future<MediaFile> cache(MediaFile file) async {
    final cachePath = await writeMediaCache(
      '${file.id}.${file.extension}',
      file.bytes,
    );

    if (cachePath == null) return file;

    return file.copyWith(path: cachePath);
  }

  Future<void> remove(MediaFile file) async {
    final path = file.path;
    if (path == null) return;

    await removeMediaCache(path);
  }

  Future<void> clear() async {
    await clearMediaCache();
  }
}
