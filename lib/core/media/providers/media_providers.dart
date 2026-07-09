import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/service_providers.dart';
import '../../supabase/storage/supabase_storage_provider.dart';
import '../services/media_services.dart';

final imagePickerProvider = Provider<ImagePicker>((ref) {
  return ImagePicker();
});

final imageProcessingServiceProvider = Provider<ImageProcessingService>((ref) {
  return const ImageProcessingService();
});

final mediaCacheServiceProvider = Provider<MediaCacheService>((ref) {
  return const MediaCacheService();
});

final mediaValidationServiceProvider = Provider<MediaValidationService>((ref) {
  return const MediaValidationService();
});

final mediaPickerServiceProvider = Provider<MediaPickerService>((ref) {
  return MediaPickerService(
    uuidService: ref.watch(uuidServiceProvider),
    imagePicker: ref.watch(imagePickerProvider),
    imageProcessingService: ref.watch(imageProcessingServiceProvider),
    cacheService: ref.watch(mediaCacheServiceProvider),
  );
});

final mediaUploadServiceProvider = Provider<MediaUploadService>((ref) {
  return MediaUploadService(storageService: ref.watch(supabaseStorageProvider));
});
