import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/failures/failures.dart';

void main() {
  group('Failure', () {
    test('creates a validation failure with message and code', () {
      const failure = ValidationFailure(
        message: 'Campo obrigatório.',
        code: 'required_field',
      );

      expect(failure.message, 'Campo obrigatório.');
      expect(failure.code, 'required_field');
    });

    test('creates a storage failure for persistence errors', () {
      const failure = StorageFailure(
        message: 'Não foi possível salvar os dados.',
        code: 'storage_write_failed',
      );

      expect(failure.message, 'Não foi possível salvar os dados.');
      expect(failure.code, 'storage_write_failed');
    });

    test('creates an unexpected failure without a code', () {
      const failure = UnexpectedFailure(message: 'Erro inesperado.');

      expect(failure.message, 'Erro inesperado.');
      expect(failure.code, isNull);
    });

    test('compares failures by type, message, and code', () {
      const first = ValidationFailure(
        message: 'Valor inválido.',
        code: 'invalid_value',
      );
      const second = ValidationFailure(
        message: 'Valor inválido.',
        code: 'invalid_value',
      );
      const differentType = UnexpectedFailure(
        message: 'Valor inválido.',
        code: 'invalid_value',
      );

      expect(first, second);
      expect(first, isNot(differentType));
    });

    test('converts failure to app exception', () {
      const failure = StorageFailure(
        message: 'Não foi possível carregar os dados.',
        code: 'storage_read_failed',
      );

      final exception = failure.toException();

      expect(exception.message, failure.message);
      expect(exception.code, failure.code);
    });
  });
}
