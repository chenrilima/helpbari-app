import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/errors/app_exception.dart';
import 'package:helpbari/core/result/result.dart';

void main() {
  group('Result', () {
    test('should create success result', () {
      const result = Success<String>('HelpBari');

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.data, 'HelpBari');
    });

    test('should create failure result', () {
      const exception = AppException(message: 'Erro ao carregar dados');
      const result = Failure<String>(exception);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.exception.message, 'Erro ao carregar dados');
    });
  });
}