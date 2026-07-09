import '../../errors/app_exception.dart';
import '../../failures/failure.dart';

AppException mapMediaException(
  Object error,
  StackTrace stackTrace, {
  String fallbackMessage = 'Não foi possível processar o arquivo.',
}) {
  if (error is AppException) return error;

  return StorageFailure(
    message: fallbackMessage,
    code: 'media_error',
  ).toException(stackTrace: stackTrace);
}
