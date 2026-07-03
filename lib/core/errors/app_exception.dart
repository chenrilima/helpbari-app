class AppException implements Exception {
  const AppException({
    required this.message,
    this.code,
    this.stackTrace,
  });

  final String message;
  final String? code;
  final StackTrace? stackTrace;

  @override
  String toString() {
    if (code == null) {
      return 'AppException(message: $message)';
    }

    return 'AppException(code: $code, message: $message)';
  }
}