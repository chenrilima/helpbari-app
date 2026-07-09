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
}

final class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code});
}

final class StorageFailure extends Failure {
  const StorageFailure({required super.message, super.code});
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure({required super.message, super.code});
}
