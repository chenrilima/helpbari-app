import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/app_exception.dart';
import '../failures/failures.dart' as domain_failures;

abstract final class SupabaseErrorMapper {
  static AppException map(
    Object error,
    StackTrace stackTrace, {
    String fallbackMessage = 'Erro inesperado ao comunicar com o Supabase.',
  }) {
    if (error is AppException) {
      return AppException(
        message: error.message,
        code: error.code,
        stackTrace: stackTrace,
      );
    }

    if (error is AuthException) {
      return domain_failures.AuthFailure(
        message: error.message,
        code: error.statusCode,
      ).toException(stackTrace: stackTrace);
    }

    if (error is PostgrestException) {
      return domain_failures.DatabaseFailure(
        message: error.message,
        code: error.code,
      ).toException(stackTrace: stackTrace);
    }

    if (error is StorageException) {
      return domain_failures.StorageFailure(
        message: error.message,
        code: error.statusCode,
      ).toException(stackTrace: stackTrace);
    }

    if (error is FunctionException) {
      return domain_failures.EdgeFunctionFailure(
        message: error.reasonPhrase ?? fallbackMessage,
        code: error.status.toString(),
      ).toException(stackTrace: stackTrace);
    }

    return domain_failures.UnexpectedFailure(
      message: fallbackMessage,
    ).toException(stackTrace: stackTrace);
  }
}
