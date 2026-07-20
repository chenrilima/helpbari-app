final class SmartRoutineValidationException implements Exception {
  const SmartRoutineValidationException(this.code, this.message);

  final String code;
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmartRoutineValidationException &&
          code == other.code &&
          message == other.message;

  @override
  int get hashCode => Object.hash(code, message);

  @override
  String toString() => 'SmartRoutineValidationException($code: $message)';
}
