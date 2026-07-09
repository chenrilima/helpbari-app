import '../../errors/app_exception.dart';
import '../../failures/failure.dart';
import '../models/media_file.dart';
import '../models/media_validation_config.dart';

class MediaValidationService {
  const MediaValidationService();

  AppException? validateFile(
    MediaFile file, {
    MediaValidationConfig config = const MediaValidationConfig(),
  }) {
    if (!config.allowedTypes.contains(file.type)) {
      return const ValidationFailure(
        message: 'Tipo de arquivo não permitido.',
        code: 'media_type_not_allowed',
      ).toException();
    }

    final maxSize = config.maxSizeFor(file.type);
    if (file.sizeInBytes > maxSize) {
      return ValidationFailure(
        message: 'O arquivo excede o tamanho máximo permitido.',
        code: 'media_file_too_large',
      ).toException();
    }

    return null;
  }

  AppException? validateFiles(
    List<MediaFile> files, {
    MediaValidationConfig config = const MediaValidationConfig(),
  }) {
    if (config.required && files.isEmpty) {
      return const ValidationFailure(
        message: 'Selecione pelo menos um arquivo.',
        code: 'media_required',
      ).toException();
    }

    if (files.length > config.maxFiles) {
      return ValidationFailure(
        message: 'Selecione no máximo ${config.maxFiles} arquivo(s).',
        code: 'media_too_many_files',
      ).toException();
    }

    for (final file in files) {
      final error = validateFile(file, config: config);
      if (error != null) return error;
    }

    return null;
  }
}
