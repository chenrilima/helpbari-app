import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/core/formatters/app_input_formatters.dart';
import 'package:helpbari/core/validators/app_validators.dart';

void main() {
  group('AppInputFormatters', () {
    test('applies the Brazilian date mask and limits it to eight digits', () {
      final result = AppInputFormatters.date.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '1307202612'),
      );

      expect(result.text, '13/07/2026');
      expect(result.selection.baseOffset, result.text.length);
    });

    test('rejects a second decimal separator and excess decimals', () {
      final formatter = AppInputFormatters.decimal().single;
      const valid = TextEditingValue(text: '91,5');

      expect(
        formatter.formatEditUpdate(
          valid,
          const TextEditingValue(text: '91,55'),
        ),
        valid,
      );
      expect(
        formatter.formatEditUpdate(
          valid,
          const TextEditingValue(text: '91,5.'),
        ),
        valid,
      );
    });
  });

  group('AppValidators', () {
    test('validates real calendar dates', () {
      expect(AppValidators.date('29/02/2024'), isNull);
      expect(AppValidators.date('31/02/2024'), isNotNull);
    });

    test('validates water amount boundaries', () {
      expect(AppValidators.waterAmount('1'), isNull);
      expect(AppValidators.waterAmount('10000'), isNull);
      expect(AppValidators.waterAmount('0'), isNotNull);
      expect(AppValidators.waterAmount('10001'), isNotNull);
    });

    test('limits optional long text', () {
      expect(AppValidators.optionalText(List.filled(500, 'a').join()), isNull);
      expect(
        AppValidators.optionalText(List.filled(501, 'a').join()),
        isNotNull,
      );
    });
  });
}
