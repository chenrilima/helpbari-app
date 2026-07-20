import 'privacy_local_file_cleanup_stub.dart'
    if (dart.library.io) 'privacy_local_file_cleanup_io.dart';

class PrivacyLocalFileCleanupService {
  const PrivacyLocalFileCleanupService();

  Future<void> clearKnownFiles(Iterable<String?> paths) =>
      removeKnownPrivacyFiles(paths.whereType<String>());
}
