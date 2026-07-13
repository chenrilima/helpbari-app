import 'app_exception.dart';

abstract final class PresentationErrorMapper {
  static String message(Object error, {required String fallback}) {
    return switch (error) {
      AppException(:final message) => message,
      FormatException(:final message) when message.isNotEmpty => message,
      ArgumentError(:final message) when message != null => message.toString(),
      _ => fallback,
    };
  }
}
