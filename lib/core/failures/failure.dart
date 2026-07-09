import '../errors/app_exception.dart';

sealed class Failure {
  const Failure({required this.message, this.code});

  final String message;
  final String? code;

  @override
  String toString() {
    if (code == null) {
      return '$runtimeType(message: $message)';
    }

    return '$runtimeType(code: $code, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Failure &&
            other.runtimeType == runtimeType &&
            other.message == message &&
            other.code == code;
  }

  @override
  int get hashCode => Object.hash(runtimeType, message, code);

  AppException toException({StackTrace? stackTrace}) {
    return AppException(message: message, code: code, stackTrace: stackTrace);
  }
}

final class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code});
}

final class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

final class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code});
}

final class StorageFailure extends Failure {
  const StorageFailure({required super.message, super.code});
}

final class DatabaseFailure extends Failure {
  const DatabaseFailure({required super.message, super.code});
}

final class RealtimeFailure extends Failure {
  const RealtimeFailure({required super.message, super.code});
}

final class EdgeFunctionFailure extends Failure {
  const EdgeFunctionFailure({required super.message, super.code});
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure({required super.message, super.code});
}
