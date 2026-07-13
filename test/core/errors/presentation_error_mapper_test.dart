import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/errors/app_exception.dart';
import 'package:helpbari/core/errors/presentation_error_mapper.dart';

void main() {
  test('returns friendly messages without technical exception prefixes', () {
    expect(
      PresentationErrorMapper.message(
        const FormatException('Aceite os documentos.'),
        fallback: 'Falha.',
      ),
      'Aceite os documentos.',
    );
    expect(
      PresentationErrorMapper.message(
        const AppException(message: 'Revise os dados.'),
        fallback: 'Falha.',
      ),
      'Revise os dados.',
    );
    expect(
      PresentationErrorMapper.message(Object(), fallback: 'Falha amigável.'),
      'Falha amigável.',
    );
  });
}
