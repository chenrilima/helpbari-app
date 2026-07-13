import 'package:flutter/services.dart';

abstract final class AppInputFormatters {
  static final TextInputFormatter date = _DateInputFormatter();

  static List<TextInputFormatter> text({required int maxLength}) => [
    LengthLimitingTextInputFormatter(maxLength),
  ];

  static final List<TextInputFormatter> email = [
    FilteringTextInputFormatter.deny(RegExp(r'\s')),
    LengthLimitingTextInputFormatter(254),
  ];

  static List<TextInputFormatter> digits({required int maxLength}) => [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(maxLength),
  ];

  static List<TextInputFormatter> decimal({
    int maxIntegerDigits = 3,
    int decimalDigits = 1,
  }) => [
    TextInputFormatter.withFunction((oldValue, newValue) {
      final pattern = RegExp(
        '^\\d{0,$maxIntegerDigits}(?:[,.]\\d{0,$decimalDigits})?\$',
      );
      return pattern.hasMatch(newValue.text) ? newValue : oldValue;
    }),
  ];
}

final class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 8 ? digits.substring(0, 8) : digits;
    final buffer = StringBuffer();

    for (var index = 0; index < limited.length; index++) {
      if (index == 2 || index == 4) buffer.write('/');
      buffer.write(limited[index]);
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
